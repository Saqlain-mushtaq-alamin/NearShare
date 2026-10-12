import 'dart:io';

import '../domain/chunk_info.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_session.dart';
import 'file_storage_service.dart';
import 'transfer_session_repository.dart';

/// Splits files into chunks, tracks which chunks have landed on disk and
/// assembles the final file once every chunk is present.
///
/// All bookkeeping is delegated to a [TransferSessionRepository] so interrupted
/// transfers survive process death.
class ChunkManager {
  static const int defaultChunkSize = kDefaultChunkSize;

  final TransferSessionRepository repository;
  final FileStorageService storageService;

  ChunkManager({
    required this.repository,
    FileStorageService? storageService,
  }) : storageService = storageService ?? FileStorageService();

  /// Splits [file] into fixed-size chunks, the last one holding the remainder.
  List<ChunkInfo> splitFileIntoChunks(TransferFile file, int chunkSize) {
    return chunkRangesForSize(file.sizeInBytes, chunkSize);
  }

  /// Same as [splitFileIntoChunks] but with the default chunk size.
  List<ChunkInfo> defaultSplit(TransferFile file) {
    return splitFileIntoChunks(file, defaultChunkSize);
  }

  /// Byte ranges expected for a file already registered on a session.
  List<ChunkInfo> chunkPlanFor(TransferSession session, int fileIndex) {
    if (fileIndex < 0 || fileIndex >= session.files.length) return const [];
    return chunkRangesForSize(
      session.files[fileIndex].sizeInBytes,
      session.chunkSize,
    );
  }

  /// Durably stores a single chunk on disk and records it on the session.
  ///
  /// The bytes are first written to a temporary file and then renamed so a
  /// torn write can never be mistaken for a complete chunk.
  Future<void> writeChunk({
    required String transferId,
    required int fileIndex,
    required int chunkIndex,
    required List<int> bytes,
  }) async {
    final session = await _requireSession(transferId);
    final plan = chunkPlanFor(session, fileIndex);

    if (fileIndex < 0 || fileIndex >= session.files.length) {
      throw RangeError.range(fileIndex, 0, session.files.length - 1, 'fileIndex');
    }
    if (chunkIndex < 0 || chunkIndex >= plan.length) {
      throw RangeError.range(chunkIndex, 0, plan.length - 1, 'chunkIndex');
    }

    final expected = plan[chunkIndex];
    if (bytes.length != expected.size) {
      throw ArgumentError(
        'Chunk $chunkIndex of $transferId/$fileIndex expected '
        '${expected.size} bytes but received ${bytes.length}',
      );
    }

    final target = await storageService.chunkFileFor(
      transferId,
      fileIndex,
      chunkIndex,
    );
    final staging = File('${target.path}.tmp');
    await staging.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await staging.rename(target.path);

    await markChunkReceived(transferId, fileIndex, chunkIndex);
  }

  /// Records that [chunkIndex] of [fileIndex] has been received.
  Future<void> markChunkReceived(
    String transferId,
    int fileIndex,
    int chunkIndex,
  ) async {
    final session = await _requireSession(transferId);
    final existing = session.receivedChunksPerFile[fileIndex] ?? const <int>[];
    if (existing.contains(chunkIndex)) return;

    final updated = <int, List<int>>{
      for (final entry in session.receivedChunksPerFile.entries)
        entry.key: List<int>.from(entry.value),
    };
    updated[fileIndex] = [...existing, chunkIndex];

    await repository.saveSession(
      session.copyWith(
        receivedChunksPerFile: updated,
        lastActivityAt: DateTime.now(),
        status: session.status == TransferSessionStatus.pending
            ? TransferSessionStatus.inProgress
            : session.status,
      ),
    );
  }

  /// Chunk indices of [fileIndex] that are still missing.
  ///
  /// Recorded-but-lost chunks (for example a partial file deleted by the user)
  /// are dropped from the session first so a restart is requested.
  Future<List<int>> getMissingChunks(
    String transferId,
    int fileIndex,
  ) async {
    await reconcileFile(transferId, fileIndex);
    final session = await _requireSession(transferId);
    return session.missingChunksForFile(fileIndex);
  }

  /// Whether every chunk of [fileIndex] is present and verified on disk.
  Future<bool> isFileComplete(String transferId, int fileIndex) async {
    await reconcileFile(transferId, fileIndex);
    final session = await repository.getSession(transferId);
    if (session == null) return false;
    if (session.fileSavePaths.containsKey(fileIndex)) return true;
    return session.isFileComplete(fileIndex);
  }

  /// Drops chunk bookkeeping whose backing file no longer exists on disk.
  ///
  /// Returns `true` when the session had to be corrected.
  Future<bool> reconcileFile(String transferId, int fileIndex) async {
    final session = await repository.getSession(transferId);
    if (session == null) return false;
    if (fileIndex < 0 || fileIndex >= session.files.length) return false;
    if (session.fileSavePaths.containsKey(fileIndex)) return false;

    final recorded = session.receivedChunksForFile(fileIndex);
    if (recorded.isEmpty) return false;

    final plan = chunkPlanFor(session, fileIndex);
    final valid = <int>[];
    var changed = false;

    for (final index in recorded) {
      if (index < 0 || index >= plan.length) {
        changed = true;
        continue;
      }
      final chunkFile = File(
        await _chunkPath(transferId, fileIndex, index),
      );
      if (await chunkFile.exists() &&
          await chunkFile.length() == plan[index].size) {
        valid.add(index);
      } else {
        changed = true;
      }
    }

    if (!changed) return false;

    final updated = Map<int, List<int>>.from(
      session.receivedChunksPerFile,
    );
    updated[fileIndex] = valid;
    await repository.saveSession(
      session.copyWith(
        receivedChunksPerFile: updated,
        lastActivityAt: DateTime.now(),
      ),
    );
    return true;
  }

  /// Concatenates every stored chunk into the final destination file.
  ///
  /// Throws a [StateError] when chunks are still missing.
  Future<File> assembleFile(String transferId, int fileIndex) async {
    final session = await _requireSession(transferId);
    if (fileIndex < 0 || fileIndex >= session.files.length) {
      throw RangeError.range(fileIndex, 0, session.files.length - 1, 'fileIndex');
    }

    final existingPath = session.fileSavePaths[fileIndex];
    if (existingPath != null) {
      final existing = File(existingPath);
      if (await existing.exists()) return existing;
    }

    final complete = await isFileComplete(transferId, fileIndex);
    if (!complete) {
      throw StateError(
        'Cannot assemble $transferId/$fileIndex: chunks are still missing',
      );
    }

    final fileMeta = session.files[fileIndex];
    final destination = await storageService.prepareDestinationFile(fileMeta.name);

    final sink = destination.openWrite();
    try {
      final plan = chunkPlanFor(session, fileIndex);
      for (final chunk in plan) {
        final chunkFile = File(
          await _chunkPath(transferId, fileIndex, chunk.index),
        );
        await sink.addStream(chunkFile.openRead());
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    final written = await destination.length();
    if (written != fileMeta.sizeInBytes) {
      await destination.delete();
      throw StateError(
        'Assembled file for $transferId/$fileIndex is $written bytes, '
        'expected ${fileMeta.sizeInBytes}',
      );
    }

    final updatedChunks = Map<int, List<int>>.from(
      session.receivedChunksPerFile,
    );
    updatedChunks[fileIndex] = [
      for (final chunk in chunkPlanFor(session, fileIndex)) chunk.index,
    ];
    final updatedPaths = Map<int, String>.from(session.fileSavePaths)
      ..[fileIndex] = destination.path;

    final allDone = updatedPaths.length >= session.files.length;
    await repository.saveSession(
      session.copyWith(
        receivedChunksPerFile: updatedChunks,
        fileSavePaths: updatedPaths,
        lastActivityAt: DateTime.now(),
        status: allDone ? TransferSessionStatus.completed : session.status,
        completedAt: allDone ? DateTime.now() : session.completedAt,
      ),
    );

    await storageService.deleteFileTempDataFor(transferId, fileIndex);
    if (allDone) {
      await storageService.deleteTempDataFor(transferId);
    }

    return destination;
  }

  /// Removes staged chunks for a single file, forcing a full re-send of it.
  Future<void> discardFile(String transferId, int fileIndex) async {
    final session = await repository.getSession(transferId);
    if (session == null) return;

    await storageService.deleteFileTempDataFor(transferId, fileIndex);

    final updatedChunks = Map<int, List<int>>.from(
      session.receivedChunksPerFile,
    )
      ..remove(fileIndex);
    final updatedPaths = Map<int, String>.from(session.fileSavePaths)
      ..remove(fileIndex);
    await repository.saveSession(
      session.copyWith(
        receivedChunksPerFile: updatedChunks,
        fileSavePaths: updatedPaths,
        lastActivityAt: DateTime.now(),
      ),
    );
  }

  /// Removes every staged byte and forgets the chunk bookkeeping of a session.
  ///
  /// Used when a transfer is cancelled by either side.
  Future<void> discardTransfer(String transferId) async {
    final session = await repository.getSession(transferId);
    await storageService.deleteTempDataFor(transferId);
    if (session == null) return;

    await repository.saveSession(
      session.copyWith(
        receivedChunksPerFile: const {},
        fileSavePaths: const {},
        lastActivityAt: DateTime.now(),
        status: TransferSessionStatus.cancelled,
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<TransferSession> _requireSession(String transferId) async {
    final session = await repository.getSession(transferId);
    if (session == null) {
      throw StateError('Transfer session $transferId not found');
    }
    return session;
  }

  Future<String> _chunkPath(
    String transferId,
    int fileIndex,
    int chunkIndex,
  ) async {
    final file = await storageService.chunkFileFor(
      transferId,
      fileIndex,
      chunkIndex,
    );
    return file.path;
  }
}
