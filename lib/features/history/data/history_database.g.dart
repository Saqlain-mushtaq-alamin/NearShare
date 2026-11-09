// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_database.dart';

// ignore_for_file: type=lint
class $SessionRecordsTable extends SessionRecords
    with TableInfo<$SessionRecordsTable, SessionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'session_records';
  @override
  VerificationContext validateIntegrity(Insertable<SessionRecord> instance,
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
  SessionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRecord(
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
  $SessionRecordsTable createAlias(String alias) {
    return $SessionRecordsTable(attachedDatabase, alias);
  }
}

class SessionRecord extends DataClass implements Insertable<SessionRecord> {
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
  const SessionRecord(
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

  SessionRecordsCompanion toCompanion(bool nullToAbsent) {
    return SessionRecordsCompanion(
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

  factory SessionRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRecord(
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

  SessionRecord copyWith(
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
      SessionRecord(
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
  SessionRecord copyWithCompanion(SessionRecordsCompanion data) {
    return SessionRecord(
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
    return (StringBuffer('SessionRecord(')
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
      (other is SessionRecord &&
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

class SessionRecordsCompanion extends UpdateCompanion<SessionRecord> {
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
  const SessionRecordsCompanion({
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
  SessionRecordsCompanion.insert({
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
  static Insertable<SessionRecord> custom({
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

  SessionRecordsCompanion copyWith(
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
    return SessionRecordsCompanion(
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
    return (StringBuffer('SessionRecordsCompanion(')
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

class $TransferHistoryRecordsTable extends TransferHistoryRecords
    with TableInfo<$TransferHistoryRecordsTable, TransferHistoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferHistoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transferIdMeta =
      const VerificationMeta('transferId');
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
      'transfer_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerDeviceIdMeta =
      const VerificationMeta('peerDeviceId');
  @override
  late final GeneratedColumn<String> peerDeviceId = GeneratedColumn<String>(
      'peer_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerDeviceNameMeta =
      const VerificationMeta('peerDeviceName');
  @override
  late final GeneratedColumn<String> peerDeviceName = GeneratedColumn<String>(
      'peer_device_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalFilesMeta =
      const VerificationMeta('totalFiles');
  @override
  late final GeneratedColumn<int> totalFiles = GeneratedColumn<int>(
      'total_files', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalSizeBytesMeta =
      const VerificationMeta('totalSizeBytes');
  @override
  late final GeneratedColumn<int> totalSizeBytes = GeneratedColumn<int>(
      'total_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        transferId,
        direction,
        peerDeviceId,
        peerDeviceName,
        totalFiles,
        totalSizeBytes,
        status,
        timestamp,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_history_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransferHistoryRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
          _transferIdMeta,
          transferId.isAcceptableOrUnknown(
              data['transfer_id']!, _transferIdMeta));
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('peer_device_id')) {
      context.handle(
          _peerDeviceIdMeta,
          peerDeviceId.isAcceptableOrUnknown(
              data['peer_device_id']!, _peerDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_peerDeviceIdMeta);
    }
    if (data.containsKey('peer_device_name')) {
      context.handle(
          _peerDeviceNameMeta,
          peerDeviceName.isAcceptableOrUnknown(
              data['peer_device_name']!, _peerDeviceNameMeta));
    } else if (isInserting) {
      context.missing(_peerDeviceNameMeta);
    }
    if (data.containsKey('total_files')) {
      context.handle(
          _totalFilesMeta,
          totalFiles.isAcceptableOrUnknown(
              data['total_files']!, _totalFilesMeta));
    } else if (isInserting) {
      context.missing(_totalFilesMeta);
    }
    if (data.containsKey('total_size_bytes')) {
      context.handle(
          _totalSizeBytesMeta,
          totalSizeBytes.isAcceptableOrUnknown(
              data['total_size_bytes']!, _totalSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_totalSizeBytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferHistoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferHistoryRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transferId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transfer_id'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      peerDeviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_device_id'])!,
      peerDeviceName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}peer_device_name'])!,
      totalFiles: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_files'])!,
      totalSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_size_bytes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $TransferHistoryRecordsTable createAlias(String alias) {
    return $TransferHistoryRecordsTable(attachedDatabase, alias);
  }
}

class TransferHistoryRecord extends DataClass
    implements Insertable<TransferHistoryRecord> {
  final int id;
  final String transferId;
  final String direction;
  final String peerDeviceId;
  final String peerDeviceName;
  final int totalFiles;
  final int totalSizeBytes;
  final String status;
  final DateTime timestamp;
  final DateTime? completedAt;
  const TransferHistoryRecord(
      {required this.id,
      required this.transferId,
      required this.direction,
      required this.peerDeviceId,
      required this.peerDeviceName,
      required this.totalFiles,
      required this.totalSizeBytes,
      required this.status,
      required this.timestamp,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transfer_id'] = Variable<String>(transferId);
    map['direction'] = Variable<String>(direction);
    map['peer_device_id'] = Variable<String>(peerDeviceId);
    map['peer_device_name'] = Variable<String>(peerDeviceName);
    map['total_files'] = Variable<int>(totalFiles);
    map['total_size_bytes'] = Variable<int>(totalSizeBytes);
    map['status'] = Variable<String>(status);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  TransferHistoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return TransferHistoryRecordsCompanion(
      id: Value(id),
      transferId: Value(transferId),
      direction: Value(direction),
      peerDeviceId: Value(peerDeviceId),
      peerDeviceName: Value(peerDeviceName),
      totalFiles: Value(totalFiles),
      totalSizeBytes: Value(totalSizeBytes),
      status: Value(status),
      timestamp: Value(timestamp),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory TransferHistoryRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferHistoryRecord(
      id: serializer.fromJson<int>(json['id']),
      transferId: serializer.fromJson<String>(json['transferId']),
      direction: serializer.fromJson<String>(json['direction']),
      peerDeviceId: serializer.fromJson<String>(json['peerDeviceId']),
      peerDeviceName: serializer.fromJson<String>(json['peerDeviceName']),
      totalFiles: serializer.fromJson<int>(json['totalFiles']),
      totalSizeBytes: serializer.fromJson<int>(json['totalSizeBytes']),
      status: serializer.fromJson<String>(json['status']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transferId': serializer.toJson<String>(transferId),
      'direction': serializer.toJson<String>(direction),
      'peerDeviceId': serializer.toJson<String>(peerDeviceId),
      'peerDeviceName': serializer.toJson<String>(peerDeviceName),
      'totalFiles': serializer.toJson<int>(totalFiles),
      'totalSizeBytes': serializer.toJson<int>(totalSizeBytes),
      'status': serializer.toJson<String>(status),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  TransferHistoryRecord copyWith(
          {int? id,
          String? transferId,
          String? direction,
          String? peerDeviceId,
          String? peerDeviceName,
          int? totalFiles,
          int? totalSizeBytes,
          String? status,
          DateTime? timestamp,
          Value<DateTime?> completedAt = const Value.absent()}) =>
      TransferHistoryRecord(
        id: id ?? this.id,
        transferId: transferId ?? this.transferId,
        direction: direction ?? this.direction,
        peerDeviceId: peerDeviceId ?? this.peerDeviceId,
        peerDeviceName: peerDeviceName ?? this.peerDeviceName,
        totalFiles: totalFiles ?? this.totalFiles,
        totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
        status: status ?? this.status,
        timestamp: timestamp ?? this.timestamp,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  TransferHistoryRecord copyWithCompanion(
      TransferHistoryRecordsCompanion data) {
    return TransferHistoryRecord(
      id: data.id.present ? data.id.value : this.id,
      transferId:
          data.transferId.present ? data.transferId.value : this.transferId,
      direction: data.direction.present ? data.direction.value : this.direction,
      peerDeviceId: data.peerDeviceId.present
          ? data.peerDeviceId.value
          : this.peerDeviceId,
      peerDeviceName: data.peerDeviceName.present
          ? data.peerDeviceName.value
          : this.peerDeviceName,
      totalFiles:
          data.totalFiles.present ? data.totalFiles.value : this.totalFiles,
      totalSizeBytes: data.totalSizeBytes.present
          ? data.totalSizeBytes.value
          : this.totalSizeBytes,
      status: data.status.present ? data.status.value : this.status,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryRecord(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('direction: $direction, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalSizeBytes: $totalSizeBytes, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      transferId,
      direction,
      peerDeviceId,
      peerDeviceName,
      totalFiles,
      totalSizeBytes,
      status,
      timestamp,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferHistoryRecord &&
          other.id == this.id &&
          other.transferId == this.transferId &&
          other.direction == this.direction &&
          other.peerDeviceId == this.peerDeviceId &&
          other.peerDeviceName == this.peerDeviceName &&
          other.totalFiles == this.totalFiles &&
          other.totalSizeBytes == this.totalSizeBytes &&
          other.status == this.status &&
          other.timestamp == this.timestamp &&
          other.completedAt == this.completedAt);
}

class TransferHistoryRecordsCompanion
    extends UpdateCompanion<TransferHistoryRecord> {
  final Value<int> id;
  final Value<String> transferId;
  final Value<String> direction;
  final Value<String> peerDeviceId;
  final Value<String> peerDeviceName;
  final Value<int> totalFiles;
  final Value<int> totalSizeBytes;
  final Value<String> status;
  final Value<DateTime> timestamp;
  final Value<DateTime?> completedAt;
  const TransferHistoryRecordsCompanion({
    this.id = const Value.absent(),
    this.transferId = const Value.absent(),
    this.direction = const Value.absent(),
    this.peerDeviceId = const Value.absent(),
    this.peerDeviceName = const Value.absent(),
    this.totalFiles = const Value.absent(),
    this.totalSizeBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TransferHistoryRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String transferId,
    required String direction,
    required String peerDeviceId,
    required String peerDeviceName,
    required int totalFiles,
    required int totalSizeBytes,
    required String status,
    required DateTime timestamp,
    this.completedAt = const Value.absent(),
  })  : transferId = Value(transferId),
        direction = Value(direction),
        peerDeviceId = Value(peerDeviceId),
        peerDeviceName = Value(peerDeviceName),
        totalFiles = Value(totalFiles),
        totalSizeBytes = Value(totalSizeBytes),
        status = Value(status),
        timestamp = Value(timestamp);
  static Insertable<TransferHistoryRecord> custom({
    Expression<int>? id,
    Expression<String>? transferId,
    Expression<String>? direction,
    Expression<String>? peerDeviceId,
    Expression<String>? peerDeviceName,
    Expression<int>? totalFiles,
    Expression<int>? totalSizeBytes,
    Expression<String>? status,
    Expression<DateTime>? timestamp,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferId != null) 'transfer_id': transferId,
      if (direction != null) 'direction': direction,
      if (peerDeviceId != null) 'peer_device_id': peerDeviceId,
      if (peerDeviceName != null) 'peer_device_name': peerDeviceName,
      if (totalFiles != null) 'total_files': totalFiles,
      if (totalSizeBytes != null) 'total_size_bytes': totalSizeBytes,
      if (status != null) 'status': status,
      if (timestamp != null) 'timestamp': timestamp,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TransferHistoryRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? transferId,
      Value<String>? direction,
      Value<String>? peerDeviceId,
      Value<String>? peerDeviceName,
      Value<int>? totalFiles,
      Value<int>? totalSizeBytes,
      Value<String>? status,
      Value<DateTime>? timestamp,
      Value<DateTime?>? completedAt}) {
    return TransferHistoryRecordsCompanion(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      direction: direction ?? this.direction,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      totalFiles: totalFiles ?? this.totalFiles,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (peerDeviceId.present) {
      map['peer_device_id'] = Variable<String>(peerDeviceId.value);
    }
    if (peerDeviceName.present) {
      map['peer_device_name'] = Variable<String>(peerDeviceName.value);
    }
    if (totalFiles.present) {
      map['total_files'] = Variable<int>(totalFiles.value);
    }
    if (totalSizeBytes.present) {
      map['total_size_bytes'] = Variable<int>(totalSizeBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('direction: $direction, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalSizeBytes: $totalSizeBytes, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $TransferHistoryFileRecordsTable extends TransferHistoryFileRecords
    with
        TableInfo<$TransferHistoryFileRecordsTable, TransferHistoryFileRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferHistoryFileRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transferIdMeta =
      const VerificationMeta('transferId');
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
      'transfer_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transfer_history_records (transfer_id) ON DELETE CASCADE'));
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, transferId, fileName, fileSizeBytes, mimeType, localPath, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_history_file_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransferHistoryFileRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
          _transferIdMeta,
          transferId.isAcceptableOrUnknown(
              data['transfer_id']!, _transferIdMeta));
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferHistoryFileRecord map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferHistoryFileRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transferId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transfer_id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $TransferHistoryFileRecordsTable createAlias(String alias) {
    return $TransferHistoryFileRecordsTable(attachedDatabase, alias);
  }
}

class TransferHistoryFileRecord extends DataClass
    implements Insertable<TransferHistoryFileRecord> {
  final int id;
  final String transferId;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String? localPath;
  final String status;
  const TransferHistoryFileRecord(
      {required this.id,
      required this.transferId,
      required this.fileName,
      required this.fileSizeBytes,
      required this.mimeType,
      this.localPath,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transfer_id'] = Variable<String>(transferId);
    map['file_name'] = Variable<String>(fileName);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  TransferHistoryFileRecordsCompanion toCompanion(bool nullToAbsent) {
    return TransferHistoryFileRecordsCompanion(
      id: Value(id),
      transferId: Value(transferId),
      fileName: Value(fileName),
      fileSizeBytes: Value(fileSizeBytes),
      mimeType: Value(mimeType),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      status: Value(status),
    );
  }

  factory TransferHistoryFileRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferHistoryFileRecord(
      id: serializer.fromJson<int>(json['id']),
      transferId: serializer.fromJson<String>(json['transferId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transferId': serializer.toJson<String>(transferId),
      'fileName': serializer.toJson<String>(fileName),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'localPath': serializer.toJson<String?>(localPath),
      'status': serializer.toJson<String>(status),
    };
  }

  TransferHistoryFileRecord copyWith(
          {int? id,
          String? transferId,
          String? fileName,
          int? fileSizeBytes,
          String? mimeType,
          Value<String?> localPath = const Value.absent(),
          String? status}) =>
      TransferHistoryFileRecord(
        id: id ?? this.id,
        transferId: transferId ?? this.transferId,
        fileName: fileName ?? this.fileName,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        mimeType: mimeType ?? this.mimeType,
        localPath: localPath.present ? localPath.value : this.localPath,
        status: status ?? this.status,
      );
  TransferHistoryFileRecord copyWithCompanion(
      TransferHistoryFileRecordsCompanion data) {
    return TransferHistoryFileRecord(
      id: data.id.present ? data.id.value : this.id,
      transferId:
          data.transferId.present ? data.transferId.value : this.transferId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryFileRecord(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('localPath: $localPath, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, transferId, fileName, fileSizeBytes, mimeType, localPath, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferHistoryFileRecord &&
          other.id == this.id &&
          other.transferId == this.transferId &&
          other.fileName == this.fileName &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.localPath == this.localPath &&
          other.status == this.status);
}

class TransferHistoryFileRecordsCompanion
    extends UpdateCompanion<TransferHistoryFileRecord> {
  final Value<int> id;
  final Value<String> transferId;
  final Value<String> fileName;
  final Value<int> fileSizeBytes;
  final Value<String> mimeType;
  final Value<String?> localPath;
  final Value<String> status;
  const TransferHistoryFileRecordsCompanion({
    this.id = const Value.absent(),
    this.transferId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.status = const Value.absent(),
  });
  TransferHistoryFileRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String transferId,
    required String fileName,
    required int fileSizeBytes,
    required String mimeType,
    this.localPath = const Value.absent(),
    required String status,
  })  : transferId = Value(transferId),
        fileName = Value(fileName),
        fileSizeBytes = Value(fileSizeBytes),
        mimeType = Value(mimeType),
        status = Value(status);
  static Insertable<TransferHistoryFileRecord> custom({
    Expression<int>? id,
    Expression<String>? transferId,
    Expression<String>? fileName,
    Expression<int>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<String>? localPath,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferId != null) 'transfer_id': transferId,
      if (fileName != null) 'file_name': fileName,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (localPath != null) 'local_path': localPath,
      if (status != null) 'status': status,
    });
  }

  TransferHistoryFileRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? transferId,
      Value<String>? fileName,
      Value<int>? fileSizeBytes,
      Value<String>? mimeType,
      Value<String?>? localPath,
      Value<String>? status}) {
    return TransferHistoryFileRecordsCompanion(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryFileRecordsCompanion(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('localPath: $localPath, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$NearShareDatabase extends GeneratedDatabase {
  _$NearShareDatabase(QueryExecutor e) : super(e);
  $NearShareDatabaseManager get managers => $NearShareDatabaseManager(this);
  late final $SessionRecordsTable sessionRecords = $SessionRecordsTable(this);
  late final $TransferHistoryRecordsTable transferHistoryRecords =
      $TransferHistoryRecordsTable(this);
  late final $TransferHistoryFileRecordsTable transferHistoryFileRecords =
      $TransferHistoryFileRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [sessionRecords, transferHistoryRecords, transferHistoryFileRecords];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('transfer_history_records',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transfer_history_file_records',
                  kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$SessionRecordsTableCreateCompanionBuilder = SessionRecordsCompanion
    Function({
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
typedef $$SessionRecordsTableUpdateCompanionBuilder = SessionRecordsCompanion
    Function({
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

class $$SessionRecordsTableFilterComposer
    extends Composer<_$NearShareDatabase, $SessionRecordsTable> {
  $$SessionRecordsTableFilterComposer({
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

class $$SessionRecordsTableOrderingComposer
    extends Composer<_$NearShareDatabase, $SessionRecordsTable> {
  $$SessionRecordsTableOrderingComposer({
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

class $$SessionRecordsTableAnnotationComposer
    extends Composer<_$NearShareDatabase, $SessionRecordsTable> {
  $$SessionRecordsTableAnnotationComposer({
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

class $$SessionRecordsTableTableManager extends RootTableManager<
    _$NearShareDatabase,
    $SessionRecordsTable,
    SessionRecord,
    $$SessionRecordsTableFilterComposer,
    $$SessionRecordsTableOrderingComposer,
    $$SessionRecordsTableAnnotationComposer,
    $$SessionRecordsTableCreateCompanionBuilder,
    $$SessionRecordsTableUpdateCompanionBuilder,
    (
      SessionRecord,
      BaseReferences<_$NearShareDatabase, $SessionRecordsTable, SessionRecord>
    ),
    SessionRecord,
    PrefetchHooks Function()> {
  $$SessionRecordsTableTableManager(
      _$NearShareDatabase db, $SessionRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionRecordsTableAnnotationComposer($db: db, $table: table),
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
              SessionRecordsCompanion(
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
              SessionRecordsCompanion.insert(
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

typedef $$SessionRecordsTableProcessedTableManager = ProcessedTableManager<
    _$NearShareDatabase,
    $SessionRecordsTable,
    SessionRecord,
    $$SessionRecordsTableFilterComposer,
    $$SessionRecordsTableOrderingComposer,
    $$SessionRecordsTableAnnotationComposer,
    $$SessionRecordsTableCreateCompanionBuilder,
    $$SessionRecordsTableUpdateCompanionBuilder,
    (
      SessionRecord,
      BaseReferences<_$NearShareDatabase, $SessionRecordsTable, SessionRecord>
    ),
    SessionRecord,
    PrefetchHooks Function()>;
typedef $$TransferHistoryRecordsTableCreateCompanionBuilder
    = TransferHistoryRecordsCompanion Function({
  Value<int> id,
  required String transferId,
  required String direction,
  required String peerDeviceId,
  required String peerDeviceName,
  required int totalFiles,
  required int totalSizeBytes,
  required String status,
  required DateTime timestamp,
  Value<DateTime?> completedAt,
});
typedef $$TransferHistoryRecordsTableUpdateCompanionBuilder
    = TransferHistoryRecordsCompanion Function({
  Value<int> id,
  Value<String> transferId,
  Value<String> direction,
  Value<String> peerDeviceId,
  Value<String> peerDeviceName,
  Value<int> totalFiles,
  Value<int> totalSizeBytes,
  Value<String> status,
  Value<DateTime> timestamp,
  Value<DateTime?> completedAt,
});

final class $$TransferHistoryRecordsTableReferences extends BaseReferences<
    _$NearShareDatabase, $TransferHistoryRecordsTable, TransferHistoryRecord> {
  $$TransferHistoryRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransferHistoryFileRecordsTable,
      List<TransferHistoryFileRecord>> _transferHistoryFileRecordsRefsTable(
          _$NearShareDatabase db) =>
      MultiTypedResultKey.fromTable(db.transferHistoryFileRecords,
          aliasName: $_aliasNameGenerator(db.transferHistoryRecords.transferId,
              db.transferHistoryFileRecords.transferId));

  $$TransferHistoryFileRecordsTableProcessedTableManager
      get transferHistoryFileRecordsRefs {
    final manager = $$TransferHistoryFileRecordsTableTableManager(
            $_db, $_db.transferHistoryFileRecords)
        .filter((f) => f.transferId.transferId
            .sqlEquals($_itemColumn<String>('transfer_id')!));

    final cache = $_typedResult
        .readTableOrNull(_transferHistoryFileRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TransferHistoryRecordsTableFilterComposer
    extends Composer<_$NearShareDatabase, $TransferHistoryRecordsTable> {
  $$TransferHistoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerDeviceId => $composableBuilder(
      column: $table.peerDeviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> transferHistoryFileRecordsRefs(
      Expression<bool> Function(
              $$TransferHistoryFileRecordsTableFilterComposer f)
          f) {
    final $$TransferHistoryFileRecordsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transferId,
            referencedTable: $db.transferHistoryFileRecords,
            getReferencedColumn: (t) => t.transferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransferHistoryFileRecordsTableFilterComposer(
                  $db: $db,
                  $table: $db.transferHistoryFileRecords,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$TransferHistoryRecordsTableOrderingComposer
    extends Composer<_$NearShareDatabase, $TransferHistoryRecordsTable> {
  $$TransferHistoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerDeviceId => $composableBuilder(
      column: $table.peerDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$TransferHistoryRecordsTableAnnotationComposer
    extends Composer<_$NearShareDatabase, $TransferHistoryRecordsTable> {
  $$TransferHistoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transferId => $composableBuilder(
      column: $table.transferId, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get peerDeviceId => $composableBuilder(
      column: $table.peerDeviceId, builder: (column) => column);

  GeneratedColumn<String> get peerDeviceName => $composableBuilder(
      column: $table.peerDeviceName, builder: (column) => column);

  GeneratedColumn<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => column);

  GeneratedColumn<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  Expression<T> transferHistoryFileRecordsRefs<T extends Object>(
      Expression<T> Function(
              $$TransferHistoryFileRecordsTableAnnotationComposer a)
          f) {
    final $$TransferHistoryFileRecordsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transferId,
            referencedTable: $db.transferHistoryFileRecords,
            getReferencedColumn: (t) => t.transferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransferHistoryFileRecordsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transferHistoryFileRecords,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$TransferHistoryRecordsTableTableManager extends RootTableManager<
    _$NearShareDatabase,
    $TransferHistoryRecordsTable,
    TransferHistoryRecord,
    $$TransferHistoryRecordsTableFilterComposer,
    $$TransferHistoryRecordsTableOrderingComposer,
    $$TransferHistoryRecordsTableAnnotationComposer,
    $$TransferHistoryRecordsTableCreateCompanionBuilder,
    $$TransferHistoryRecordsTableUpdateCompanionBuilder,
    (TransferHistoryRecord, $$TransferHistoryRecordsTableReferences),
    TransferHistoryRecord,
    PrefetchHooks Function({bool transferHistoryFileRecordsRefs})> {
  $$TransferHistoryRecordsTableTableManager(
      _$NearShareDatabase db, $TransferHistoryRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferHistoryRecordsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferHistoryRecordsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferHistoryRecordsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> transferId = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> peerDeviceId = const Value.absent(),
            Value<String> peerDeviceName = const Value.absent(),
            Value<int> totalFiles = const Value.absent(),
            Value<int> totalSizeBytes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              TransferHistoryRecordsCompanion(
            id: id,
            transferId: transferId,
            direction: direction,
            peerDeviceId: peerDeviceId,
            peerDeviceName: peerDeviceName,
            totalFiles: totalFiles,
            totalSizeBytes: totalSizeBytes,
            status: status,
            timestamp: timestamp,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String transferId,
            required String direction,
            required String peerDeviceId,
            required String peerDeviceName,
            required int totalFiles,
            required int totalSizeBytes,
            required String status,
            required DateTime timestamp,
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              TransferHistoryRecordsCompanion.insert(
            id: id,
            transferId: transferId,
            direction: direction,
            peerDeviceId: peerDeviceId,
            peerDeviceName: peerDeviceName,
            totalFiles: totalFiles,
            totalSizeBytes: totalSizeBytes,
            status: status,
            timestamp: timestamp,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransferHistoryRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transferHistoryFileRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transferHistoryFileRecordsRefs)
                  db.transferHistoryFileRecords
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transferHistoryFileRecordsRefs)
                    await $_getPrefetchedData<
                            TransferHistoryRecord,
                            $TransferHistoryRecordsTable,
                            TransferHistoryFileRecord>(
                        currentTable: table,
                        referencedTable: $$TransferHistoryRecordsTableReferences
                            ._transferHistoryFileRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransferHistoryRecordsTableReferences(
                                    db, table, p0)
                                .transferHistoryFileRecordsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.transferId == item.transferId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TransferHistoryRecordsTableProcessedTableManager
    = ProcessedTableManager<
        _$NearShareDatabase,
        $TransferHistoryRecordsTable,
        TransferHistoryRecord,
        $$TransferHistoryRecordsTableFilterComposer,
        $$TransferHistoryRecordsTableOrderingComposer,
        $$TransferHistoryRecordsTableAnnotationComposer,
        $$TransferHistoryRecordsTableCreateCompanionBuilder,
        $$TransferHistoryRecordsTableUpdateCompanionBuilder,
        (TransferHistoryRecord, $$TransferHistoryRecordsTableReferences),
        TransferHistoryRecord,
        PrefetchHooks Function({bool transferHistoryFileRecordsRefs})>;
typedef $$TransferHistoryFileRecordsTableCreateCompanionBuilder
    = TransferHistoryFileRecordsCompanion Function({
  Value<int> id,
  required String transferId,
  required String fileName,
  required int fileSizeBytes,
  required String mimeType,
  Value<String?> localPath,
  required String status,
});
typedef $$TransferHistoryFileRecordsTableUpdateCompanionBuilder
    = TransferHistoryFileRecordsCompanion Function({
  Value<int> id,
  Value<String> transferId,
  Value<String> fileName,
  Value<int> fileSizeBytes,
  Value<String> mimeType,
  Value<String?> localPath,
  Value<String> status,
});

final class $$TransferHistoryFileRecordsTableReferences extends BaseReferences<
    _$NearShareDatabase,
    $TransferHistoryFileRecordsTable,
    TransferHistoryFileRecord> {
  $$TransferHistoryFileRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TransferHistoryRecordsTable _transferIdTable(
          _$NearShareDatabase db) =>
      db.transferHistoryRecords.createAlias($_aliasNameGenerator(
          db.transferHistoryFileRecords.transferId,
          db.transferHistoryRecords.transferId));

  $$TransferHistoryRecordsTableProcessedTableManager get transferId {
    final $_column = $_itemColumn<String>('transfer_id')!;

    final manager = $$TransferHistoryRecordsTableTableManager(
            $_db, $_db.transferHistoryRecords)
        .filter((f) => f.transferId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transferIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransferHistoryFileRecordsTableFilterComposer
    extends Composer<_$NearShareDatabase, $TransferHistoryFileRecordsTable> {
  $$TransferHistoryFileRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  $$TransferHistoryRecordsTableFilterComposer get transferId {
    final $$TransferHistoryRecordsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transferId,
            referencedTable: $db.transferHistoryRecords,
            getReferencedColumn: (t) => t.transferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransferHistoryRecordsTableFilterComposer(
                  $db: $db,
                  $table: $db.transferHistoryRecords,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$TransferHistoryFileRecordsTableOrderingComposer
    extends Composer<_$NearShareDatabase, $TransferHistoryFileRecordsTable> {
  $$TransferHistoryFileRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  $$TransferHistoryRecordsTableOrderingComposer get transferId {
    final $$TransferHistoryRecordsTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transferId,
            referencedTable: $db.transferHistoryRecords,
            getReferencedColumn: (t) => t.transferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransferHistoryRecordsTableOrderingComposer(
                  $db: $db,
                  $table: $db.transferHistoryRecords,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$TransferHistoryFileRecordsTableAnnotationComposer
    extends Composer<_$NearShareDatabase, $TransferHistoryFileRecordsTable> {
  $$TransferHistoryFileRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$TransferHistoryRecordsTableAnnotationComposer get transferId {
    final $$TransferHistoryRecordsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transferId,
            referencedTable: $db.transferHistoryRecords,
            getReferencedColumn: (t) => t.transferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransferHistoryRecordsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transferHistoryRecords,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$TransferHistoryFileRecordsTableTableManager extends RootTableManager<
    _$NearShareDatabase,
    $TransferHistoryFileRecordsTable,
    TransferHistoryFileRecord,
    $$TransferHistoryFileRecordsTableFilterComposer,
    $$TransferHistoryFileRecordsTableOrderingComposer,
    $$TransferHistoryFileRecordsTableAnnotationComposer,
    $$TransferHistoryFileRecordsTableCreateCompanionBuilder,
    $$TransferHistoryFileRecordsTableUpdateCompanionBuilder,
    (TransferHistoryFileRecord, $$TransferHistoryFileRecordsTableReferences),
    TransferHistoryFileRecord,
    PrefetchHooks Function({bool transferId})> {
  $$TransferHistoryFileRecordsTableTableManager(
      _$NearShareDatabase db, $TransferHistoryFileRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferHistoryFileRecordsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferHistoryFileRecordsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferHistoryFileRecordsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> transferId = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              TransferHistoryFileRecordsCompanion(
            id: id,
            transferId: transferId,
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            localPath: localPath,
            status: status,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String transferId,
            required String fileName,
            required int fileSizeBytes,
            required String mimeType,
            Value<String?> localPath = const Value.absent(),
            required String status,
          }) =>
              TransferHistoryFileRecordsCompanion.insert(
            id: id,
            transferId: transferId,
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            localPath: localPath,
            status: status,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransferHistoryFileRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transferId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transferId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transferId,
                    referencedTable: $$TransferHistoryFileRecordsTableReferences
                        ._transferIdTable(db),
                    referencedColumn:
                        $$TransferHistoryFileRecordsTableReferences
                            ._transferIdTable(db)
                            .transferId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransferHistoryFileRecordsTableProcessedTableManager
    = ProcessedTableManager<
        _$NearShareDatabase,
        $TransferHistoryFileRecordsTable,
        TransferHistoryFileRecord,
        $$TransferHistoryFileRecordsTableFilterComposer,
        $$TransferHistoryFileRecordsTableOrderingComposer,
        $$TransferHistoryFileRecordsTableAnnotationComposer,
        $$TransferHistoryFileRecordsTableCreateCompanionBuilder,
        $$TransferHistoryFileRecordsTableUpdateCompanionBuilder,
        (
          TransferHistoryFileRecord,
          $$TransferHistoryFileRecordsTableReferences
        ),
        TransferHistoryFileRecord,
        PrefetchHooks Function({bool transferId})>;

class $NearShareDatabaseManager {
  final _$NearShareDatabase _db;
  $NearShareDatabaseManager(this._db);
  $$SessionRecordsTableTableManager get sessionRecords =>
      $$SessionRecordsTableTableManager(_db, _db.sessionRecords);
  $$TransferHistoryRecordsTableTableManager get transferHistoryRecords =>
      $$TransferHistoryRecordsTableTableManager(
          _db, _db.transferHistoryRecords);
  $$TransferHistoryFileRecordsTableTableManager
      get transferHistoryFileRecords =>
          $$TransferHistoryFileRecordsTableTableManager(
              _db, _db.transferHistoryFileRecords);
}

mixin _$TransferHistoryDaoMixin on DatabaseAccessor<NearShareDatabase> {
  $TransferHistoryRecordsTable get transferHistoryRecords =>
      attachedDatabase.transferHistoryRecords;
  $TransferHistoryFileRecordsTable get transferHistoryFileRecords =>
      attachedDatabase.transferHistoryFileRecords;
}
