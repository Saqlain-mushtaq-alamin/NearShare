// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_session_database.dart';

// ignore_for_file: type=lint
class $TransferSessionsTable extends TransferSessions
    with TableInfo<$TransferSessionsTable, TransferSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transferIdMeta =
      const VerificationMeta('transferId');
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
      'transfer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
      'peer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerNameMeta =
      const VerificationMeta('peerName');
  @override
  late final GeneratedColumn<String> peerName = GeneratedColumn<String>(
      'peer_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerIpMeta = const VerificationMeta('peerIp');
  @override
  late final GeneratedColumn<String> peerIp = GeneratedColumn<String>(
      'peer_ip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _peerPortMeta =
      const VerificationMeta('peerPort');
  @override
  late final GeneratedColumn<int> peerPort = GeneratedColumn<int>(
      'peer_port', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chunkSizeMeta =
      const VerificationMeta('chunkSize');
  @override
  late final GeneratedColumn<int> chunkSize = GeneratedColumn<int>(
      'chunk_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _localDeviceIdMeta =
      const VerificationMeta('localDeviceId');
  @override
  late final GeneratedColumn<String> localDeviceId = GeneratedColumn<String>(
      'local_device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localDeviceNameMeta =
      const VerificationMeta('localDeviceName');
  @override
  late final GeneratedColumn<String> localDeviceName = GeneratedColumn<String>(
      'local_device_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filesJsonMeta =
      const VerificationMeta('filesJson');
  @override
  late final GeneratedColumn<String> filesJson = GeneratedColumn<String>(
      'files_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _receivedChunksJsonMeta =
      const VerificationMeta('receivedChunksJson');
  @override
  late final GeneratedColumn<String> receivedChunksJson =
      GeneratedColumn<String>('received_chunks_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSavePathsJsonMeta =
      const VerificationMeta('fileSavePathsJson');
  @override
  late final GeneratedColumn<String> fileSavePathsJson =
      GeneratedColumn<String>('file_save_paths_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastActivityAtMeta =
      const VerificationMeta('lastActivityAt');
  @override
  late final GeneratedColumn<DateTime> lastActivityAt =
      GeneratedColumn<DateTime>('last_activity_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        transferId,
        peerId,
        peerName,
        peerIp,
        peerPort,
        direction,
        status,
        chunkSize,
        localDeviceId,
        localDeviceName,
        filesJson,
        receivedChunksJson,
        fileSavePathsJson,
        startedAt,
        lastActivityAt,
        completedAt,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<TransferSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transfer_id')) {
      context.handle(
          _transferIdMeta,
          transferId.isAcceptableOrUnknown(
              data['transfer_id']!, _transferIdMeta));
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(_peerIdMeta,
          peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta));
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('peer_name')) {
      context.handle(_peerNameMeta,
          peerName.isAcceptableOrUnknown(data['peer_name']!, _peerNameMeta));
    } else if (isInserting) {
      context.missing(_peerNameMeta);
    }
    if (data.containsKey('peer_ip')) {
      context.handle(_peerIpMeta,
          peerIp.isAcceptableOrUnknown(data['peer_ip']!, _peerIpMeta));
    }
    if (data.containsKey('peer_port')) {
      context.handle(_peerPortMeta,
          peerPort.isAcceptableOrUnknown(data['peer_port']!, _peerPortMeta));
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('chunk_size')) {
      context.handle(_chunkSizeMeta,
          chunkSize.isAcceptableOrUnknown(data['chunk_size']!, _chunkSizeMeta));
    } else if (isInserting) {
      context.missing(_chunkSizeMeta);
    }
    if (data.containsKey('local_device_id')) {
      context.handle(
          _localDeviceIdMeta,
          localDeviceId.isAcceptableOrUnknown(
              data['local_device_id']!, _localDeviceIdMeta));
    }
    if (data.containsKey('local_device_name')) {
      context.handle(
          _localDeviceNameMeta,
          localDeviceName.isAcceptableOrUnknown(
              data['local_device_name']!, _localDeviceNameMeta));
    }
    if (data.containsKey('files_json')) {
      context.handle(_filesJsonMeta,
          filesJson.isAcceptableOrUnknown(data['files_json']!, _filesJsonMeta));
    } else if (isInserting) {
      context.missing(_filesJsonMeta);
    }
    if (data.containsKey('received_chunks_json')) {
      context.handle(
          _receivedChunksJsonMeta,
          receivedChunksJson.isAcceptableOrUnknown(
              data['received_chunks_json']!, _receivedChunksJsonMeta));
    } else if (isInserting) {
      context.missing(_receivedChunksJsonMeta);
    }
    if (data.containsKey('file_save_paths_json')) {
      context.handle(
          _fileSavePathsJsonMeta,
          fileSavePathsJson.isAcceptableOrUnknown(
              data['file_save_paths_json']!, _fileSavePathsJsonMeta));
    } else if (isInserting) {
      context.missing(_fileSavePathsJsonMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('last_activity_at')) {
      context.handle(
          _lastActivityAtMeta,
          lastActivityAt.isAcceptableOrUnknown(
              data['last_activity_at']!, _lastActivityAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transferId};
  @override
  TransferSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferSession(
      transferId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transfer_id'])!,
      peerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_id'])!,
      peerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_name'])!,
      peerIp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_ip']),
      peerPort: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}peer_port']),
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      chunkSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chunk_size'])!,
      localDeviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_device_id']),
      localDeviceName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_device_name']),
      filesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}files_json'])!,
      receivedChunksJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}received_chunks_json'])!,
      fileSavePathsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}file_save_paths_json'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      lastActivityAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_activity_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $TransferSessionsTable createAlias(String alias) {
    return $TransferSessionsTable(attachedDatabase, alias);
  }
}

class TransferSession extends DataClass implements Insertable<TransferSession> {
  final String transferId;
  final String peerId;
  final String peerName;
  final String? peerIp;
  final int? peerPort;
  final String direction;
  final String status;
  final int chunkSize;
  final String? localDeviceId;
  final String? localDeviceName;
  final String filesJson;
  final String receivedChunksJson;
  final String fileSavePathsJson;
  final DateTime startedAt;
  final DateTime? lastActivityAt;
  final DateTime? completedAt;
  final String? errorMessage;
  const TransferSession(
      {required this.transferId,
      required this.peerId,
      required this.peerName,
      this.peerIp,
      this.peerPort,
      required this.direction,
      required this.status,
      required this.chunkSize,
      this.localDeviceId,
      this.localDeviceName,
      required this.filesJson,
      required this.receivedChunksJson,
      required this.fileSavePathsJson,
      required this.startedAt,
      this.lastActivityAt,
      this.completedAt,
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transfer_id'] = Variable<String>(transferId);
    map['peer_id'] = Variable<String>(peerId);
    map['peer_name'] = Variable<String>(peerName);
    if (!nullToAbsent || peerIp != null) {
      map['peer_ip'] = Variable<String>(peerIp);
    }
    if (!nullToAbsent || peerPort != null) {
      map['peer_port'] = Variable<int>(peerPort);
    }
    map['direction'] = Variable<String>(direction);
    map['status'] = Variable<String>(status);
    map['chunk_size'] = Variable<int>(chunkSize);
    if (!nullToAbsent || localDeviceId != null) {
      map['local_device_id'] = Variable<String>(localDeviceId);
    }
    if (!nullToAbsent || localDeviceName != null) {
      map['local_device_name'] = Variable<String>(localDeviceName);
    }
    map['files_json'] = Variable<String>(filesJson);
    map['received_chunks_json'] = Variable<String>(receivedChunksJson);
    map['file_save_paths_json'] = Variable<String>(fileSavePathsJson);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || lastActivityAt != null) {
      map['last_activity_at'] = Variable<DateTime>(lastActivityAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  TransferSessionsCompanion toCompanion(bool nullToAbsent) {
    return TransferSessionsCompanion(
      transferId: Value(transferId),
      peerId: Value(peerId),
      peerName: Value(peerName),
      peerIp:
          peerIp == null && nullToAbsent ? const Value.absent() : Value(peerIp),
      peerPort: peerPort == null && nullToAbsent
          ? const Value.absent()
          : Value(peerPort),
      direction: Value(direction),
      status: Value(status),
      chunkSize: Value(chunkSize),
      localDeviceId: localDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(localDeviceId),
      localDeviceName: localDeviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(localDeviceName),
      filesJson: Value(filesJson),
      receivedChunksJson: Value(receivedChunksJson),
      fileSavePathsJson: Value(fileSavePathsJson),
      startedAt: Value(startedAt),
      lastActivityAt: lastActivityAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory TransferSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferSession(
      transferId: serializer.fromJson<String>(json['transferId']),
      peerId: serializer.fromJson<String>(json['peerId']),
      peerName: serializer.fromJson<String>(json['peerName']),
      peerIp: serializer.fromJson<String?>(json['peerIp']),
      peerPort: serializer.fromJson<int?>(json['peerPort']),
      direction: serializer.fromJson<String>(json['direction']),
      status: serializer.fromJson<String>(json['status']),
      chunkSize: serializer.fromJson<int>(json['chunkSize']),
      localDeviceId: serializer.fromJson<String?>(json['localDeviceId']),
      localDeviceName: serializer.fromJson<String?>(json['localDeviceName']),
      filesJson: serializer.fromJson<String>(json['filesJson']),
      receivedChunksJson:
          serializer.fromJson<String>(json['receivedChunksJson']),
      fileSavePathsJson: serializer.fromJson<String>(json['fileSavePathsJson']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastActivityAt: serializer.fromJson<DateTime?>(json['lastActivityAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transferId': serializer.toJson<String>(transferId),
      'peerId': serializer.toJson<String>(peerId),
      'peerName': serializer.toJson<String>(peerName),
      'peerIp': serializer.toJson<String?>(peerIp),
      'peerPort': serializer.toJson<int?>(peerPort),
      'direction': serializer.toJson<String>(direction),
      'status': serializer.toJson<String>(status),
      'chunkSize': serializer.toJson<int>(chunkSize),
      'localDeviceId': serializer.toJson<String?>(localDeviceId),
      'localDeviceName': serializer.toJson<String?>(localDeviceName),
      'filesJson': serializer.toJson<String>(filesJson),
      'receivedChunksJson': serializer.toJson<String>(receivedChunksJson),
      'fileSavePathsJson': serializer.toJson<String>(fileSavePathsJson),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastActivityAt': serializer.toJson<DateTime?>(lastActivityAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  TransferSession copyWith(
          {String? transferId,
          String? peerId,
          String? peerName,
          Value<String?> peerIp = const Value.absent(),
          Value<int?> peerPort = const Value.absent(),
          String? direction,
          String? status,
          int? chunkSize,
          Value<String?> localDeviceId = const Value.absent(),
          Value<String?> localDeviceName = const Value.absent(),
          String? filesJson,
          String? receivedChunksJson,
          String? fileSavePathsJson,
          DateTime? startedAt,
          Value<DateTime?> lastActivityAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> errorMessage = const Value.absent()}) =>
      TransferSession(
        transferId: transferId ?? this.transferId,
        peerId: peerId ?? this.peerId,
        peerName: peerName ?? this.peerName,
        peerIp: peerIp.present ? peerIp.value : this.peerIp,
        peerPort: peerPort.present ? peerPort.value : this.peerPort,
        direction: direction ?? this.direction,
        status: status ?? this.status,
        chunkSize: chunkSize ?? this.chunkSize,
        localDeviceId:
            localDeviceId.present ? localDeviceId.value : this.localDeviceId,
        localDeviceName: localDeviceName.present
            ? localDeviceName.value
            : this.localDeviceName,
        filesJson: filesJson ?? this.filesJson,
        receivedChunksJson: receivedChunksJson ?? this.receivedChunksJson,
        fileSavePathsJson: fileSavePathsJson ?? this.fileSavePathsJson,
        startedAt: startedAt ?? this.startedAt,
        lastActivityAt:
            lastActivityAt.present ? lastActivityAt.value : this.lastActivityAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  TransferSession copyWithCompanion(TransferSessionsCompanion data) {
    return TransferSession(
      transferId:
          data.transferId.present ? data.transferId.value : this.transferId,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      peerName: data.peerName.present ? data.peerName.value : this.peerName,
      peerIp: data.peerIp.present ? data.peerIp.value : this.peerIp,
      peerPort: data.peerPort.present ? data.peerPort.value : this.peerPort,
      direction: data.direction.present ? data.direction.value : this.direction,
      status: data.status.present ? data.status.value : this.status,
      chunkSize: data.chunkSize.present ? data.chunkSize.value : this.chunkSize,
      localDeviceId: data.localDeviceId.present
          ? data.localDeviceId.value
          : this.localDeviceId,
      localDeviceName: data.localDeviceName.present
          ? data.localDeviceName.value
          : this.localDeviceName,
      filesJson: data.filesJson.present ? data.filesJson.value : this.filesJson,
      receivedChunksJson: data.receivedChunksJson.present
          ? data.receivedChunksJson.value
          : this.receivedChunksJson,
      fileSavePathsJson: data.fileSavePathsJson.present
          ? data.fileSavePathsJson.value
          : this.fileSavePathsJson,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastActivityAt: data.lastActivityAt.present
          ? data.lastActivityAt.value
          : this.lastActivityAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferSession(')
          ..write('transferId: $transferId, ')
          ..write('peerId: $peerId, ')
          ..write('peerName: $peerName, ')
          ..write('peerIp: $peerIp, ')
          ..write('peerPort: $peerPort, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('chunkSize: $chunkSize, ')
          ..write('localDeviceId: $localDeviceId, ')
          ..write('localDeviceName: $localDeviceName, ')
          ..write('filesJson: $filesJson, ')
          ..write('receivedChunksJson: $receivedChunksJson, ')
          ..write('fileSavePathsJson: $fileSavePathsJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      transferId,
      peerId,
      peerName,
      peerIp,
      peerPort,
      direction,
      status,
      chunkSize,
      localDeviceId,
      localDeviceName,
      filesJson,
      receivedChunksJson,
      fileSavePathsJson,
      startedAt,
      lastActivityAt,
      completedAt,
      errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferSession &&
          other.transferId == this.transferId &&
          other.peerId == this.peerId &&
          other.peerName == this.peerName &&
          other.peerIp == this.peerIp &&
          other.peerPort == this.peerPort &&
          other.direction == this.direction &&
          other.status == this.status &&
          other.chunkSize == this.chunkSize &&
          other.localDeviceId == this.localDeviceId &&
          other.localDeviceName == this.localDeviceName &&
          other.filesJson == this.filesJson &&
          other.receivedChunksJson == this.receivedChunksJson &&
          other.fileSavePathsJson == this.fileSavePathsJson &&
          other.startedAt == this.startedAt &&
          other.lastActivityAt == this.lastActivityAt &&
          other.completedAt == this.completedAt &&
          other.errorMessage == this.errorMessage);
}

class TransferSessionsCompanion extends UpdateCompanion<TransferSession> {
  final Value<String> transferId;
  final Value<String> peerId;
  final Value<String> peerName;
  final Value<String?> peerIp;
  final Value<int?> peerPort;
  final Value<String> direction;
  final Value<String> status;
  final Value<int> chunkSize;
  final Value<String?> localDeviceId;
  final Value<String?> localDeviceName;
  final Value<String> filesJson;
  final Value<String> receivedChunksJson;
  final Value<String> fileSavePathsJson;
  final Value<DateTime> startedAt;
  final Value<DateTime?> lastActivityAt;
  final Value<DateTime?> completedAt;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const TransferSessionsCompanion({
    this.transferId = const Value.absent(),
    this.peerId = const Value.absent(),
    this.peerName = const Value.absent(),
    this.peerIp = const Value.absent(),
    this.peerPort = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    this.chunkSize = const Value.absent(),
    this.localDeviceId = const Value.absent(),
    this.localDeviceName = const Value.absent(),
    this.filesJson = const Value.absent(),
    this.receivedChunksJson = const Value.absent(),
    this.fileSavePathsJson = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastActivityAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferSessionsCompanion.insert({
    required String transferId,
    required String peerId,
    required String peerName,
    this.peerIp = const Value.absent(),
    this.peerPort = const Value.absent(),
    required String direction,
    required String status,
    required int chunkSize,
    this.localDeviceId = const Value.absent(),
    this.localDeviceName = const Value.absent(),
    required String filesJson,
    required String receivedChunksJson,
    required String fileSavePathsJson,
    required DateTime startedAt,
    this.lastActivityAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : transferId = Value(transferId),
        peerId = Value(peerId),
        peerName = Value(peerName),
        direction = Value(direction),
        status = Value(status),
        chunkSize = Value(chunkSize),
        filesJson = Value(filesJson),
        receivedChunksJson = Value(receivedChunksJson),
        fileSavePathsJson = Value(fileSavePathsJson),
        startedAt = Value(startedAt);
  static Insertable<TransferSession> custom({
    Expression<String>? transferId,
    Expression<String>? peerId,
    Expression<String>? peerName,
    Expression<String>? peerIp,
    Expression<int>? peerPort,
    Expression<String>? direction,
    Expression<String>? status,
    Expression<int>? chunkSize,
    Expression<String>? localDeviceId,
    Expression<String>? localDeviceName,
    Expression<String>? filesJson,
    Expression<String>? receivedChunksJson,
    Expression<String>? fileSavePathsJson,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastActivityAt,
    Expression<DateTime>? completedAt,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transferId != null) 'transfer_id': transferId,
      if (peerId != null) 'peer_id': peerId,
      if (peerName != null) 'peer_name': peerName,
      if (peerIp != null) 'peer_ip': peerIp,
      if (peerPort != null) 'peer_port': peerPort,
      if (direction != null) 'direction': direction,
      if (status != null) 'status': status,
      if (chunkSize != null) 'chunk_size': chunkSize,
      if (localDeviceId != null) 'local_device_id': localDeviceId,
      if (localDeviceName != null) 'local_device_name': localDeviceName,
      if (filesJson != null) 'files_json': filesJson,
      if (receivedChunksJson != null)
        'received_chunks_json': receivedChunksJson,
      if (fileSavePathsJson != null) 'file_save_paths_json': fileSavePathsJson,
      if (startedAt != null) 'started_at': startedAt,
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferSessionsCompanion copyWith(
      {Value<String>? transferId,
      Value<String>? peerId,
      Value<String>? peerName,
      Value<String?>? peerIp,
      Value<int?>? peerPort,
      Value<String>? direction,
      Value<String>? status,
      Value<int>? chunkSize,
      Value<String?>? localDeviceId,
      Value<String?>? localDeviceName,
      Value<String>? filesJson,
      Value<String>? receivedChunksJson,
      Value<String>? fileSavePathsJson,
      Value<DateTime>? startedAt,
      Value<DateTime?>? lastActivityAt,
      Value<DateTime?>? completedAt,
      Value<String?>? errorMessage,
      Value<int>? rowid}) {
    return TransferSessionsCompanion(
      transferId: transferId ?? this.transferId,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerIp: peerIp ?? this.peerIp,
      peerPort: peerPort ?? this.peerPort,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      chunkSize: chunkSize ?? this.chunkSize,
      localDeviceId: localDeviceId ?? this.localDeviceId,
      localDeviceName: localDeviceName ?? this.localDeviceName,
      filesJson: filesJson ?? this.filesJson,
      receivedChunksJson: receivedChunksJson ?? this.receivedChunksJson,
      fileSavePathsJson: fileSavePathsJson ?? this.fileSavePathsJson,
      startedAt: startedAt ?? this.startedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (peerName.present) {
      map['peer_name'] = Variable<String>(peerName.value);
    }
    if (peerIp.present) {
      map['peer_ip'] = Variable<String>(peerIp.value);
    }
    if (peerPort.present) {
      map['peer_port'] = Variable<int>(peerPort.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (chunkSize.present) {
      map['chunk_size'] = Variable<int>(chunkSize.value);
    }
    if (localDeviceId.present) {
      map['local_device_id'] = Variable<String>(localDeviceId.value);
    }
    if (localDeviceName.present) {
      map['local_device_name'] = Variable<String>(localDeviceName.value);
    }
    if (filesJson.present) {
      map['files_json'] = Variable<String>(filesJson.value);
    }
    if (receivedChunksJson.present) {
      map['received_chunks_json'] = Variable<String>(receivedChunksJson.value);
    }
    if (fileSavePathsJson.present) {
      map['file_save_paths_json'] = Variable<String>(fileSavePathsJson.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastActivityAt.present) {
      map['last_activity_at'] = Variable<DateTime>(lastActivityAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferSessionsCompanion(')
          ..write('transferId: $transferId, ')
          ..write('peerId: $peerId, ')
          ..write('peerName: $peerName, ')
          ..write('peerIp: $peerIp, ')
          ..write('peerPort: $peerPort, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('chunkSize: $chunkSize, ')
          ..write('localDeviceId: $localDeviceId, ')
          ..write('localDeviceName: $localDeviceName, ')
          ..write('filesJson: $filesJson, ')
          ..write('receivedChunksJson: $receivedChunksJson, ')
          ..write('fileSavePathsJson: $fileSavePathsJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TransferSessionDatabase extends GeneratedDatabase {
  _$TransferSessionDatabase(QueryExecutor e) : super(e);
  $TransferSessionDatabaseManager get managers =>
      $TransferSessionDatabaseManager(this);
  late final $TransferSessionsTable transferSessions =
      $TransferSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [transferSessions];
}

typedef $$TransferSessionsTableCreateCompanionBuilder
    = TransferSessionsCompanion Function({
  required String transferId,
  required String peerId,
  required String peerName,
  Value<String?> peerIp,
  Value<int?> peerPort,
  required String direction,
  required String status,
  required int chunkSize,
  Value<String?> localDeviceId,
  Value<String?> localDeviceName,
  required String filesJson,
  required String receivedChunksJson,
  required String fileSavePathsJson,
  required DateTime startedAt,
  Value<DateTime?> lastActivityAt,
  Value<DateTime?> completedAt,
  Value<String?> errorMessage,
  Value<int> rowid,
});
typedef $$TransferSessionsTableUpdateCompanionBuilder
    = TransferSessionsCompanion Function({
  Value<String> transferId,
  Value<String> peerId,
  Value<String> peerName,
  Value<String?> peerIp,
  Value<int?> peerPort,
  Value<String> direction,
  Value<String> status,
  Value<int> chunkSize,
  Value<String?> localDeviceId,
  Value<String?> localDeviceName,
  Value<String> filesJson,
  Value<String> receivedChunksJson,
  Value<String> fileSavePathsJson,
  Value<DateTime> startedAt,
  Value<DateTime?> lastActivityAt,
  Value<DateTime?> completedAt,
  Value<String?> errorMessage,
  Value<int> rowid,
});

class $$TransferSessionsTableFilterComposer
    extends Composer<_$TransferSessionDatabase, $TransferSessionsTable> {
  $$TransferSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerName => $composableBuilder(
      column: $table.peerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerIp => $composableBuilder(
      column: $table.peerIp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get peerPort => $composableBuilder(
      column: $table.peerPort, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chunkSize => $composableBuilder(
      column: $table.chunkSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localDeviceId => $composableBuilder(
      column: $table.localDeviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localDeviceName => $composableBuilder(
      column: $table.localDeviceName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filesJson => $composableBuilder(
      column: $table.filesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receivedChunksJson => $composableBuilder(
      column: $table.receivedChunksJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileSavePathsJson => $composableBuilder(
      column: $table.fileSavePathsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActivityAt => $composableBuilder(
      column: $table.lastActivityAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));
}

class $$TransferSessionsTableOrderingComposer
    extends Composer<_$TransferSessionDatabase, $TransferSessionsTable> {
  $$TransferSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerName => $composableBuilder(
      column: $table.peerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerIp => $composableBuilder(
      column: $table.peerIp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get peerPort => $composableBuilder(
      column: $table.peerPort, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chunkSize => $composableBuilder(
      column: $table.chunkSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localDeviceId => $composableBuilder(
      column: $table.localDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localDeviceName => $composableBuilder(
      column: $table.localDeviceName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filesJson => $composableBuilder(
      column: $table.filesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receivedChunksJson => $composableBuilder(
      column: $table.receivedChunksJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileSavePathsJson => $composableBuilder(
      column: $table.fileSavePathsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActivityAt => $composableBuilder(
      column: $table.lastActivityAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));
}

class $$TransferSessionsTableAnnotationComposer
    extends Composer<_$TransferSessionDatabase, $TransferSessionsTable> {
  $$TransferSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => column);

  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<String> get peerName =>
      $composableBuilder(column: $table.peerName, builder: (column) => column);

  GeneratedColumn<String> get peerIp =>
      $composableBuilder(column: $table.peerIp, builder: (column) => column);

  GeneratedColumn<int> get peerPort =>
      $composableBuilder(column: $table.peerPort, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get chunkSize =>
      $composableBuilder(column: $table.chunkSize, builder: (column) => column);

  GeneratedColumn<String> get localDeviceId => $composableBuilder(
      column: $table.localDeviceId, builder: (column) => column);

  GeneratedColumn<String> get localDeviceName => $composableBuilder(
      column: $table.localDeviceName, builder: (column) => column);

  GeneratedColumn<String> get filesJson =>
      $composableBuilder(column: $table.filesJson, builder: (column) => column);

  GeneratedColumn<String> get receivedChunksJson => $composableBuilder(
      column: $table.receivedChunksJson, builder: (column) => column);

  GeneratedColumn<String> get fileSavePathsJson => $composableBuilder(
      column: $table.fileSavePathsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActivityAt => $composableBuilder(
      column: $table.lastActivityAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);
}

class $$TransferSessionsTableTableManager extends RootTableManager<
    _$TransferSessionDatabase,
    $TransferSessionsTable,
    TransferSession,
    $$TransferSessionsTableFilterComposer,
    $$TransferSessionsTableOrderingComposer,
    $$TransferSessionsTableAnnotationComposer,
    $$TransferSessionsTableCreateCompanionBuilder,
    $$TransferSessionsTableUpdateCompanionBuilder,
    (
      TransferSession,
      BaseReferences<_$TransferSessionDatabase, $TransferSessionsTable,
          TransferSession>
    ),
    TransferSession,
    PrefetchHooks Function()> {
  $$TransferSessionsTableTableManager(
      _$TransferSessionDatabase db, $TransferSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> transferId = const Value.absent(),
            Value<String> peerId = const Value.absent(),
            Value<String> peerName = const Value.absent(),
            Value<String?> peerIp = const Value.absent(),
            Value<int?> peerPort = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> chunkSize = const Value.absent(),
            Value<String?> localDeviceId = const Value.absent(),
            Value<String?> localDeviceName = const Value.absent(),
            Value<String> filesJson = const Value.absent(),
            Value<String> receivedChunksJson = const Value.absent(),
            Value<String> fileSavePathsJson = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> lastActivityAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferSessionsCompanion(
            transferId: transferId,
            peerId: peerId,
            peerName: peerName,
            peerIp: peerIp,
            peerPort: peerPort,
            direction: direction,
            status: status,
            chunkSize: chunkSize,
            localDeviceId: localDeviceId,
            localDeviceName: localDeviceName,
            filesJson: filesJson,
            receivedChunksJson: receivedChunksJson,
            fileSavePathsJson: fileSavePathsJson,
            startedAt: startedAt,
            lastActivityAt: lastActivityAt,
            completedAt: completedAt,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String transferId,
            required String peerId,
            required String peerName,
            Value<String?> peerIp = const Value.absent(),
            Value<int?> peerPort = const Value.absent(),
            required String direction,
            required String status,
            required int chunkSize,
            Value<String?> localDeviceId = const Value.absent(),
            Value<String?> localDeviceName = const Value.absent(),
            required String filesJson,
            required String receivedChunksJson,
            required String fileSavePathsJson,
            required DateTime startedAt,
            Value<DateTime?> lastActivityAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferSessionsCompanion.insert(
            transferId: transferId,
            peerId: peerId,
            peerName: peerName,
            peerIp: peerIp,
            peerPort: peerPort,
            direction: direction,
            status: status,
            chunkSize: chunkSize,
            localDeviceId: localDeviceId,
            localDeviceName: localDeviceName,
            filesJson: filesJson,
            receivedChunksJson: receivedChunksJson,
            fileSavePathsJson: fileSavePathsJson,
            startedAt: startedAt,
            lastActivityAt: lastActivityAt,
            completedAt: completedAt,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransferSessionsTableProcessedTableManager = ProcessedTableManager<
    _$TransferSessionDatabase,
    $TransferSessionsTable,
    TransferSession,
    $$TransferSessionsTableFilterComposer,
    $$TransferSessionsTableOrderingComposer,
    $$TransferSessionsTableAnnotationComposer,
    $$TransferSessionsTableCreateCompanionBuilder,
    $$TransferSessionsTableUpdateCompanionBuilder,
    (
      TransferSession,
      BaseReferences<_$TransferSessionDatabase, $TransferSessionsTable,
          TransferSession>
    ),
    TransferSession,
    PrefetchHooks Function()>;

class $TransferSessionDatabaseManager {
  final _$TransferSessionDatabase _db;
  $TransferSessionDatabaseManager(this._db);
  $$TransferSessionsTableTableManager get transferSessions =>
      $$TransferSessionsTableTableManager(_db, _db.transferSessions);
}
