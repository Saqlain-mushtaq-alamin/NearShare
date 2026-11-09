// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $MergeSpaceFilesTable extends MergeSpaceFiles
    with TableInfo<$MergeSpaceFilesTable, MergeSpaceFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MergeSpaceFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseHashMeta =
      const VerificationMeta('baseHash');
  @override
  late final GeneratedColumn<String> baseHash = GeneratedColumn<String>(
      'base_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        relativePath,
        hash,
        baseHash,
        sizeBytes,
        modifiedAt,
        isDeleted,
        originDeviceId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merge_space_files';
  @override
  VerificationContext validateIntegrity(Insertable<MergeSpaceFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('base_hash')) {
      context.handle(_baseHashMeta,
          baseHash.isAcceptableOrUnknown(data['base_hash']!, _baseHashMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {relativePath};
  @override
  MergeSpaceFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MergeSpaceFile(
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash'])!,
      baseHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_hash']),
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
    );
  }

  @override
  $MergeSpaceFilesTable createAlias(String alias) {
    return $MergeSpaceFilesTable(attachedDatabase, alias);
  }
}

class MergeSpaceFile extends DataClass implements Insertable<MergeSpaceFile> {
  final String relativePath;
  final String hash;
  final String? baseHash;
  final int sizeBytes;
  final DateTime modifiedAt;
  final bool isDeleted;
  final String originDeviceId;
  const MergeSpaceFile(
      {required this.relativePath,
      required this.hash,
      this.baseHash,
      required this.sizeBytes,
      required this.modifiedAt,
      required this.isDeleted,
      required this.originDeviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['relative_path'] = Variable<String>(relativePath);
    map['hash'] = Variable<String>(hash);
    if (!nullToAbsent || baseHash != null) {
      map['base_hash'] = Variable<String>(baseHash);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    return map;
  }

  MergeSpaceFilesCompanion toCompanion(bool nullToAbsent) {
    return MergeSpaceFilesCompanion(
      relativePath: Value(relativePath),
      hash: Value(hash),
      baseHash: baseHash == null && nullToAbsent
          ? const Value.absent()
          : Value(baseHash),
      sizeBytes: Value(sizeBytes),
      modifiedAt: Value(modifiedAt),
      isDeleted: Value(isDeleted),
      originDeviceId: Value(originDeviceId),
    );
  }

  factory MergeSpaceFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MergeSpaceFile(
      relativePath: serializer.fromJson<String>(json['relativePath']),
      hash: serializer.fromJson<String>(json['hash']),
      baseHash: serializer.fromJson<String?>(json['baseHash']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'relativePath': serializer.toJson<String>(relativePath),
      'hash': serializer.toJson<String>(hash),
      'baseHash': serializer.toJson<String?>(baseHash),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
    };
  }

  MergeSpaceFile copyWith(
          {String? relativePath,
          String? hash,
          Value<String?> baseHash = const Value.absent(),
          int? sizeBytes,
          DateTime? modifiedAt,
          bool? isDeleted,
          String? originDeviceId}) =>
      MergeSpaceFile(
        relativePath: relativePath ?? this.relativePath,
        hash: hash ?? this.hash,
        baseHash: baseHash.present ? baseHash.value : this.baseHash,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        originDeviceId: originDeviceId ?? this.originDeviceId,
      );
  MergeSpaceFile copyWithCompanion(MergeSpaceFilesCompanion data) {
    return MergeSpaceFile(
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      hash: data.hash.present ? data.hash.value : this.hash,
      baseHash: data.baseHash.present ? data.baseHash.value : this.baseHash,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MergeSpaceFile(')
          ..write('relativePath: $relativePath, ')
          ..write('hash: $hash, ')
          ..write('baseHash: $baseHash, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('originDeviceId: $originDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(relativePath, hash, baseHash, sizeBytes,
      modifiedAt, isDeleted, originDeviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MergeSpaceFile &&
          other.relativePath == this.relativePath &&
          other.hash == this.hash &&
          other.baseHash == this.baseHash &&
          other.sizeBytes == this.sizeBytes &&
          other.modifiedAt == this.modifiedAt &&
          other.isDeleted == this.isDeleted &&
          other.originDeviceId == this.originDeviceId);
}

class MergeSpaceFilesCompanion extends UpdateCompanion<MergeSpaceFile> {
  final Value<String> relativePath;
  final Value<String> hash;
  final Value<String?> baseHash;
  final Value<int> sizeBytes;
  final Value<DateTime> modifiedAt;
  final Value<bool> isDeleted;
  final Value<String> originDeviceId;
  final Value<int> rowid;
  const MergeSpaceFilesCompanion({
    this.relativePath = const Value.absent(),
    this.hash = const Value.absent(),
    this.baseHash = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MergeSpaceFilesCompanion.insert({
    required String relativePath,
    required String hash,
    this.baseHash = const Value.absent(),
    required int sizeBytes,
    required DateTime modifiedAt,
    this.isDeleted = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : relativePath = Value(relativePath),
        hash = Value(hash),
        sizeBytes = Value(sizeBytes),
        modifiedAt = Value(modifiedAt);
  static Insertable<MergeSpaceFile> custom({
    Expression<String>? relativePath,
    Expression<String>? hash,
    Expression<String>? baseHash,
    Expression<int>? sizeBytes,
    Expression<DateTime>? modifiedAt,
    Expression<bool>? isDeleted,
    Expression<String>? originDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (relativePath != null) 'relative_path': relativePath,
      if (hash != null) 'hash': hash,
      if (baseHash != null) 'base_hash': baseHash,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MergeSpaceFilesCompanion copyWith(
      {Value<String>? relativePath,
      Value<String>? hash,
      Value<String?>? baseHash,
      Value<int>? sizeBytes,
      Value<DateTime>? modifiedAt,
      Value<bool>? isDeleted,
      Value<String>? originDeviceId,
      Value<int>? rowid}) {
    return MergeSpaceFilesCompanion(
      relativePath: relativePath ?? this.relativePath,
      hash: hash ?? this.hash,
      baseHash: baseHash ?? this.baseHash,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (baseHash.present) {
      map['base_hash'] = Variable<String>(baseHash.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MergeSpaceFilesCompanion(')
          ..write('relativePath: $relativePath, ')
          ..write('hash: $hash, ')
          ..write('baseHash: $baseHash, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PairedDevicesTable extends PairedDevices
    with TableInfo<$PairedDevicesTable, PairedDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PairedDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceNameMeta =
      const VerificationMeta('deviceName');
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
      'device_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pairedAtMeta =
      const VerificationMeta('pairedAt');
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
      'paired_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendingSync'));
  @override
  List<GeneratedColumn> get $columns => [
        deviceId,
        deviceName,
        platform,
        groupId,
        pairedAt,
        lastSyncedAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paired_devices';
  @override
  VerificationContext validateIntegrity(Insertable<PairedDevice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
          _deviceNameMeta,
          deviceName.isAcceptableOrUnknown(
              data['device_name']!, _deviceNameMeta));
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('paired_at')) {
      context.handle(_pairedAtMeta,
          pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta));
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  PairedDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PairedDevice(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deviceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_name'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      pairedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paired_at'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $PairedDevicesTable createAlias(String alias) {
    return $PairedDevicesTable(attachedDatabase, alias);
  }
}

class PairedDevice extends DataClass implements Insertable<PairedDevice> {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String groupId;
  final DateTime pairedAt;
  final DateTime? lastSyncedAt;
  final String syncStatus;
  const PairedDevice(
      {required this.deviceId,
      required this.deviceName,
      required this.platform,
      required this.groupId,
      required this.pairedAt,
      this.lastSyncedAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['device_name'] = Variable<String>(deviceName);
    map['platform'] = Variable<String>(platform);
    map['group_id'] = Variable<String>(groupId);
    map['paired_at'] = Variable<DateTime>(pairedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  PairedDevicesCompanion toCompanion(bool nullToAbsent) {
    return PairedDevicesCompanion(
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      platform: Value(platform),
      groupId: Value(groupId),
      pairedAt: Value(pairedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory PairedDevice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PairedDevice(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      platform: serializer.fromJson<String>(json['platform']),
      groupId: serializer.fromJson<String>(json['groupId']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceName': serializer.toJson<String>(deviceName),
      'platform': serializer.toJson<String>(platform),
      'groupId': serializer.toJson<String>(groupId),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  PairedDevice copyWith(
          {String? deviceId,
          String? deviceName,
          String? platform,
          String? groupId,
          DateTime? pairedAt,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          String? syncStatus}) =>
      PairedDevice(
        deviceId: deviceId ?? this.deviceId,
        deviceName: deviceName ?? this.deviceName,
        platform: platform ?? this.platform,
        groupId: groupId ?? this.groupId,
        pairedAt: pairedAt ?? this.pairedAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  PairedDevice copyWithCompanion(PairedDevicesCompanion data) {
    return PairedDevice(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName:
          data.deviceName.present ? data.deviceName.value : this.deviceName,
      platform: data.platform.present ? data.platform.value : this.platform,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevice(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('platform: $platform, ')
          ..write('groupId: $groupId, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, deviceName, platform, groupId,
      pairedAt, lastSyncedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PairedDevice &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.platform == this.platform &&
          other.groupId == this.groupId &&
          other.pairedAt == this.pairedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncStatus == this.syncStatus);
}

class PairedDevicesCompanion extends UpdateCompanion<PairedDevice> {
  final Value<String> deviceId;
  final Value<String> deviceName;
  final Value<String> platform;
  final Value<String> groupId;
  final Value<DateTime> pairedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const PairedDevicesCompanion({
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.platform = const Value.absent(),
    this.groupId = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PairedDevicesCompanion.insert({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String groupId,
    required DateTime pairedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        deviceName = Value(deviceName),
        platform = Value(platform),
        groupId = Value(groupId),
        pairedAt = Value(pairedAt);
  static Insertable<PairedDevice> custom({
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? platform,
    Expression<String>? groupId,
    Expression<DateTime>? pairedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (platform != null) 'platform': platform,
      if (groupId != null) 'group_id': groupId,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PairedDevicesCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? deviceName,
      Value<String>? platform,
      Value<String>? groupId,
      Value<DateTime>? pairedAt,
      Value<DateTime?>? lastSyncedAt,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return PairedDevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      groupId: groupId ?? this.groupId,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('platform: $platform, ')
          ..write('groupId: $groupId, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localHashMeta =
      const VerificationMeta('localHash');
  @override
  late final GeneratedColumn<String> localHash = GeneratedColumn<String>(
      'local_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteHashMeta =
      const VerificationMeta('remoteHash');
  @override
  late final GeneratedColumn<String> remoteHash = GeneratedColumn<String>(
      'remote_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localVersionJsonMeta =
      const VerificationMeta('localVersionJson');
  @override
  late final GeneratedColumn<String> localVersionJson = GeneratedColumn<String>(
      'local_version_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteVersionJsonMeta =
      const VerificationMeta('remoteVersionJson');
  @override
  late final GeneratedColumn<String> remoteVersionJson =
      GeneratedColumn<String>('remote_version_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteDeviceIdMeta =
      const VerificationMeta('remoteDeviceId');
  @override
  late final GeneratedColumn<String> remoteDeviceId = GeneratedColumn<String>(
      'remote_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detectedAtMeta =
      const VerificationMeta('detectedAt');
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
      'detected_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _resolvedMeta =
      const VerificationMeta('resolved');
  @override
  late final GeneratedColumn<bool> resolved = GeneratedColumn<bool>(
      'resolved', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("resolved" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        relativePath,
        localHash,
        remoteHash,
        localVersionJson,
        remoteVersionJson,
        remoteDeviceId,
        detectedAt,
        resolved
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(Insertable<SyncConflict> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('local_hash')) {
      context.handle(_localHashMeta,
          localHash.isAcceptableOrUnknown(data['local_hash']!, _localHashMeta));
    } else if (isInserting) {
      context.missing(_localHashMeta);
    }
    if (data.containsKey('remote_hash')) {
      context.handle(
          _remoteHashMeta,
          remoteHash.isAcceptableOrUnknown(
              data['remote_hash']!, _remoteHashMeta));
    } else if (isInserting) {
      context.missing(_remoteHashMeta);
    }
    if (data.containsKey('local_version_json')) {
      context.handle(
          _localVersionJsonMeta,
          localVersionJson.isAcceptableOrUnknown(
              data['local_version_json']!, _localVersionJsonMeta));
    } else if (isInserting) {
      context.missing(_localVersionJsonMeta);
    }
    if (data.containsKey('remote_version_json')) {
      context.handle(
          _remoteVersionJsonMeta,
          remoteVersionJson.isAcceptableOrUnknown(
              data['remote_version_json']!, _remoteVersionJsonMeta));
    } else if (isInserting) {
      context.missing(_remoteVersionJsonMeta);
    }
    if (data.containsKey('remote_device_id')) {
      context.handle(
          _remoteDeviceIdMeta,
          remoteDeviceId.isAcceptableOrUnknown(
              data['remote_device_id']!, _remoteDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_remoteDeviceIdMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
          _detectedAtMeta,
          detectedAt.isAcceptableOrUnknown(
              data['detected_at']!, _detectedAtMeta));
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    if (data.containsKey('resolved')) {
      context.handle(_resolvedMeta,
          resolved.isAcceptableOrUnknown(data['resolved']!, _resolvedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflict(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      localHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_hash'])!,
      remoteHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_hash'])!,
      localVersionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_version_json'])!,
      remoteVersionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_version_json'])!,
      remoteDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_device_id'])!,
      detectedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}detected_at'])!,
      resolved: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}resolved'])!,
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }
}

class SyncConflict extends DataClass implements Insertable<SyncConflict> {
  final int id;
  final String relativePath;
  final String localHash;
  final String remoteHash;
  final String localVersionJson;
  final String remoteVersionJson;
  final String remoteDeviceId;
  final DateTime detectedAt;
  final bool resolved;
  const SyncConflict(
      {required this.id,
      required this.relativePath,
      required this.localHash,
      required this.remoteHash,
      required this.localVersionJson,
      required this.remoteVersionJson,
      required this.remoteDeviceId,
      required this.detectedAt,
      required this.resolved});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['relative_path'] = Variable<String>(relativePath);
    map['local_hash'] = Variable<String>(localHash);
    map['remote_hash'] = Variable<String>(remoteHash);
    map['local_version_json'] = Variable<String>(localVersionJson);
    map['remote_version_json'] = Variable<String>(remoteVersionJson);
    map['remote_device_id'] = Variable<String>(remoteDeviceId);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    map['resolved'] = Variable<bool>(resolved);
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      relativePath: Value(relativePath),
      localHash: Value(localHash),
      remoteHash: Value(remoteHash),
      localVersionJson: Value(localVersionJson),
      remoteVersionJson: Value(remoteVersionJson),
      remoteDeviceId: Value(remoteDeviceId),
      detectedAt: Value(detectedAt),
      resolved: Value(resolved),
    );
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflict(
      id: serializer.fromJson<int>(json['id']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      localHash: serializer.fromJson<String>(json['localHash']),
      remoteHash: serializer.fromJson<String>(json['remoteHash']),
      localVersionJson: serializer.fromJson<String>(json['localVersionJson']),
      remoteVersionJson: serializer.fromJson<String>(json['remoteVersionJson']),
      remoteDeviceId: serializer.fromJson<String>(json['remoteDeviceId']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      resolved: serializer.fromJson<bool>(json['resolved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'relativePath': serializer.toJson<String>(relativePath),
      'localHash': serializer.toJson<String>(localHash),
      'remoteHash': serializer.toJson<String>(remoteHash),
      'localVersionJson': serializer.toJson<String>(localVersionJson),
      'remoteVersionJson': serializer.toJson<String>(remoteVersionJson),
      'remoteDeviceId': serializer.toJson<String>(remoteDeviceId),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'resolved': serializer.toJson<bool>(resolved),
    };
  }

  SyncConflict copyWith(
          {int? id,
          String? relativePath,
          String? localHash,
          String? remoteHash,
          String? localVersionJson,
          String? remoteVersionJson,
          String? remoteDeviceId,
          DateTime? detectedAt,
          bool? resolved}) =>
      SyncConflict(
        id: id ?? this.id,
        relativePath: relativePath ?? this.relativePath,
        localHash: localHash ?? this.localHash,
        remoteHash: remoteHash ?? this.remoteHash,
        localVersionJson: localVersionJson ?? this.localVersionJson,
        remoteVersionJson: remoteVersionJson ?? this.remoteVersionJson,
        remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
        detectedAt: detectedAt ?? this.detectedAt,
        resolved: resolved ?? this.resolved,
      );
  SyncConflict copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflict(
      id: data.id.present ? data.id.value : this.id,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      localHash: data.localHash.present ? data.localHash.value : this.localHash,
      remoteHash:
          data.remoteHash.present ? data.remoteHash.value : this.remoteHash,
      localVersionJson: data.localVersionJson.present
          ? data.localVersionJson.value
          : this.localVersionJson,
      remoteVersionJson: data.remoteVersionJson.present
          ? data.remoteVersionJson.value
          : this.remoteVersionJson,
      remoteDeviceId: data.remoteDeviceId.present
          ? data.remoteDeviceId.value
          : this.remoteDeviceId,
      detectedAt:
          data.detectedAt.present ? data.detectedAt.value : this.detectedAt,
      resolved: data.resolved.present ? data.resolved.value : this.resolved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflict(')
          ..write('id: $id, ')
          ..write('relativePath: $relativePath, ')
          ..write('localHash: $localHash, ')
          ..write('remoteHash: $remoteHash, ')
          ..write('localVersionJson: $localVersionJson, ')
          ..write('remoteVersionJson: $remoteVersionJson, ')
          ..write('remoteDeviceId: $remoteDeviceId, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      relativePath,
      localHash,
      remoteHash,
      localVersionJson,
      remoteVersionJson,
      remoteDeviceId,
      detectedAt,
      resolved);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflict &&
          other.id == this.id &&
          other.relativePath == this.relativePath &&
          other.localHash == this.localHash &&
          other.remoteHash == this.remoteHash &&
          other.localVersionJson == this.localVersionJson &&
          other.remoteVersionJson == this.remoteVersionJson &&
          other.remoteDeviceId == this.remoteDeviceId &&
          other.detectedAt == this.detectedAt &&
          other.resolved == this.resolved);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflict> {
  final Value<int> id;
  final Value<String> relativePath;
  final Value<String> localHash;
  final Value<String> remoteHash;
  final Value<String> localVersionJson;
  final Value<String> remoteVersionJson;
  final Value<String> remoteDeviceId;
  final Value<DateTime> detectedAt;
  final Value<bool> resolved;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.localHash = const Value.absent(),
    this.remoteHash = const Value.absent(),
    this.localVersionJson = const Value.absent(),
    this.remoteVersionJson = const Value.absent(),
    this.remoteDeviceId = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.resolved = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    this.id = const Value.absent(),
    required String relativePath,
    required String localHash,
    required String remoteHash,
    required String localVersionJson,
    required String remoteVersionJson,
    required String remoteDeviceId,
    required DateTime detectedAt,
    this.resolved = const Value.absent(),
  })  : relativePath = Value(relativePath),
        localHash = Value(localHash),
        remoteHash = Value(remoteHash),
        localVersionJson = Value(localVersionJson),
        remoteVersionJson = Value(remoteVersionJson),
        remoteDeviceId = Value(remoteDeviceId),
        detectedAt = Value(detectedAt);
  static Insertable<SyncConflict> custom({
    Expression<int>? id,
    Expression<String>? relativePath,
    Expression<String>? localHash,
    Expression<String>? remoteHash,
    Expression<String>? localVersionJson,
    Expression<String>? remoteVersionJson,
    Expression<String>? remoteDeviceId,
    Expression<DateTime>? detectedAt,
    Expression<bool>? resolved,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (relativePath != null) 'relative_path': relativePath,
      if (localHash != null) 'local_hash': localHash,
      if (remoteHash != null) 'remote_hash': remoteHash,
      if (localVersionJson != null) 'local_version_json': localVersionJson,
      if (remoteVersionJson != null) 'remote_version_json': remoteVersionJson,
      if (remoteDeviceId != null) 'remote_device_id': remoteDeviceId,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (resolved != null) 'resolved': resolved,
    });
  }

  SyncConflictsCompanion copyWith(
      {Value<int>? id,
      Value<String>? relativePath,
      Value<String>? localHash,
      Value<String>? remoteHash,
      Value<String>? localVersionJson,
      Value<String>? remoteVersionJson,
      Value<String>? remoteDeviceId,
      Value<DateTime>? detectedAt,
      Value<bool>? resolved}) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      relativePath: relativePath ?? this.relativePath,
      localHash: localHash ?? this.localHash,
      remoteHash: remoteHash ?? this.remoteHash,
      localVersionJson: localVersionJson ?? this.localVersionJson,
      remoteVersionJson: remoteVersionJson ?? this.remoteVersionJson,
      remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
      detectedAt: detectedAt ?? this.detectedAt,
      resolved: resolved ?? this.resolved,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (localHash.present) {
      map['local_hash'] = Variable<String>(localHash.value);
    }
    if (remoteHash.present) {
      map['remote_hash'] = Variable<String>(remoteHash.value);
    }
    if (localVersionJson.present) {
      map['local_version_json'] = Variable<String>(localVersionJson.value);
    }
    if (remoteVersionJson.present) {
      map['remote_version_json'] = Variable<String>(remoteVersionJson.value);
    }
    if (remoteDeviceId.present) {
      map['remote_device_id'] = Variable<String>(remoteDeviceId.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (resolved.present) {
      map['resolved'] = Variable<bool>(resolved.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('relativePath: $relativePath, ')
          ..write('localHash: $localHash, ')
          ..write('remoteHash: $remoteHash, ')
          ..write('localVersionJson: $localVersionJson, ')
          ..write('remoteVersionJson: $remoteVersionJson, ')
          ..write('remoteDeviceId: $remoteDeviceId, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }
}

abstract class _$MergeSpaceDatabase extends GeneratedDatabase {
  _$MergeSpaceDatabase(QueryExecutor e) : super(e);
  $MergeSpaceDatabaseManager get managers => $MergeSpaceDatabaseManager(this);
  late final $MergeSpaceFilesTable mergeSpaceFiles =
      $MergeSpaceFilesTable(this);
  late final $PairedDevicesTable pairedDevices = $PairedDevicesTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [mergeSpaceFiles, pairedDevices, syncConflicts];
}

typedef $$MergeSpaceFilesTableCreateCompanionBuilder = MergeSpaceFilesCompanion
    Function({
  required String relativePath,
  required String hash,
  Value<String?> baseHash,
  required int sizeBytes,
  required DateTime modifiedAt,
  Value<bool> isDeleted,
  Value<String> originDeviceId,
  Value<int> rowid,
});
typedef $$MergeSpaceFilesTableUpdateCompanionBuilder = MergeSpaceFilesCompanion
    Function({
  Value<String> relativePath,
  Value<String> hash,
  Value<String?> baseHash,
  Value<int> sizeBytes,
  Value<DateTime> modifiedAt,
  Value<bool> isDeleted,
  Value<String> originDeviceId,
  Value<int> rowid,
});

class $$MergeSpaceFilesTableFilterComposer
    extends Composer<_$MergeSpaceDatabase, $MergeSpaceFilesTable> {
  $$MergeSpaceFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseHash => $composableBuilder(
      column: $table.baseHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));
}

class $$MergeSpaceFilesTableOrderingComposer
    extends Composer<_$MergeSpaceDatabase, $MergeSpaceFilesTable> {
  $$MergeSpaceFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseHash => $composableBuilder(
      column: $table.baseHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));
}

class $$MergeSpaceFilesTableAnnotationComposer
    extends Composer<_$MergeSpaceDatabase, $MergeSpaceFilesTable> {
  $$MergeSpaceFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get baseHash =>
      $composableBuilder(column: $table.baseHash, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);
}

class $$MergeSpaceFilesTableTableManager extends RootTableManager<
    _$MergeSpaceDatabase,
    $MergeSpaceFilesTable,
    MergeSpaceFile,
    $$MergeSpaceFilesTableFilterComposer,
    $$MergeSpaceFilesTableOrderingComposer,
    $$MergeSpaceFilesTableAnnotationComposer,
    $$MergeSpaceFilesTableCreateCompanionBuilder,
    $$MergeSpaceFilesTableUpdateCompanionBuilder,
    (
      MergeSpaceFile,
      BaseReferences<_$MergeSpaceDatabase, $MergeSpaceFilesTable,
          MergeSpaceFile>
    ),
    MergeSpaceFile,
    PrefetchHooks Function()> {
  $$MergeSpaceFilesTableTableManager(
      _$MergeSpaceDatabase db, $MergeSpaceFilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MergeSpaceFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MergeSpaceFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MergeSpaceFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> relativePath = const Value.absent(),
            Value<String> hash = const Value.absent(),
            Value<String?> baseHash = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<DateTime> modifiedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MergeSpaceFilesCompanion(
            relativePath: relativePath,
            hash: hash,
            baseHash: baseHash,
            sizeBytes: sizeBytes,
            modifiedAt: modifiedAt,
            isDeleted: isDeleted,
            originDeviceId: originDeviceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String relativePath,
            required String hash,
            Value<String?> baseHash = const Value.absent(),
            required int sizeBytes,
            required DateTime modifiedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MergeSpaceFilesCompanion.insert(
            relativePath: relativePath,
            hash: hash,
            baseHash: baseHash,
            sizeBytes: sizeBytes,
            modifiedAt: modifiedAt,
            isDeleted: isDeleted,
            originDeviceId: originDeviceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MergeSpaceFilesTableProcessedTableManager = ProcessedTableManager<
    _$MergeSpaceDatabase,
    $MergeSpaceFilesTable,
    MergeSpaceFile,
    $$MergeSpaceFilesTableFilterComposer,
    $$MergeSpaceFilesTableOrderingComposer,
    $$MergeSpaceFilesTableAnnotationComposer,
    $$MergeSpaceFilesTableCreateCompanionBuilder,
    $$MergeSpaceFilesTableUpdateCompanionBuilder,
    (
      MergeSpaceFile,
      BaseReferences<_$MergeSpaceDatabase, $MergeSpaceFilesTable,
          MergeSpaceFile>
    ),
    MergeSpaceFile,
    PrefetchHooks Function()>;
typedef $$PairedDevicesTableCreateCompanionBuilder = PairedDevicesCompanion
    Function({
  required String deviceId,
  required String deviceName,
  required String platform,
  required String groupId,
  required DateTime pairedAt,
  Value<DateTime?> lastSyncedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});
typedef $$PairedDevicesTableUpdateCompanionBuilder = PairedDevicesCompanion
    Function({
  Value<String> deviceId,
  Value<String> deviceName,
  Value<String> platform,
  Value<String> groupId,
  Value<DateTime> pairedAt,
  Value<DateTime?> lastSyncedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});

class $$PairedDevicesTableFilterComposer
    extends Composer<_$MergeSpaceDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
      column: $table.pairedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$PairedDevicesTableOrderingComposer
    extends Composer<_$MergeSpaceDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
      column: $table.pairedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$PairedDevicesTableAnnotationComposer
    extends Composer<_$MergeSpaceDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$PairedDevicesTableTableManager extends RootTableManager<
    _$MergeSpaceDatabase,
    $PairedDevicesTable,
    PairedDevice,
    $$PairedDevicesTableFilterComposer,
    $$PairedDevicesTableOrderingComposer,
    $$PairedDevicesTableAnnotationComposer,
    $$PairedDevicesTableCreateCompanionBuilder,
    $$PairedDevicesTableUpdateCompanionBuilder,
    (
      PairedDevice,
      BaseReferences<_$MergeSpaceDatabase, $PairedDevicesTable, PairedDevice>
    ),
    PairedDevice,
    PrefetchHooks Function()> {
  $$PairedDevicesTableTableManager(
      _$MergeSpaceDatabase db, $PairedDevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PairedDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PairedDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PairedDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<String> deviceName = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<DateTime> pairedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PairedDevicesCompanion(
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
            groupId: groupId,
            pairedAt: pairedAt,
            lastSyncedAt: lastSyncedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required String deviceName,
            required String platform,
            required String groupId,
            required DateTime pairedAt,
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PairedDevicesCompanion.insert(
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
            groupId: groupId,
            pairedAt: pairedAt,
            lastSyncedAt: lastSyncedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PairedDevicesTableProcessedTableManager = ProcessedTableManager<
    _$MergeSpaceDatabase,
    $PairedDevicesTable,
    PairedDevice,
    $$PairedDevicesTableFilterComposer,
    $$PairedDevicesTableOrderingComposer,
    $$PairedDevicesTableAnnotationComposer,
    $$PairedDevicesTableCreateCompanionBuilder,
    $$PairedDevicesTableUpdateCompanionBuilder,
    (
      PairedDevice,
      BaseReferences<_$MergeSpaceDatabase, $PairedDevicesTable, PairedDevice>
    ),
    PairedDevice,
    PrefetchHooks Function()>;
typedef $$SyncConflictsTableCreateCompanionBuilder = SyncConflictsCompanion
    Function({
  Value<int> id,
  required String relativePath,
  required String localHash,
  required String remoteHash,
  required String localVersionJson,
  required String remoteVersionJson,
  required String remoteDeviceId,
  required DateTime detectedAt,
  Value<bool> resolved,
});
typedef $$SyncConflictsTableUpdateCompanionBuilder = SyncConflictsCompanion
    Function({
  Value<int> id,
  Value<String> relativePath,
  Value<String> localHash,
  Value<String> remoteHash,
  Value<String> localVersionJson,
  Value<String> remoteVersionJson,
  Value<String> remoteDeviceId,
  Value<DateTime> detectedAt,
  Value<bool> resolved,
});

class $$SyncConflictsTableFilterComposer
    extends Composer<_$MergeSpaceDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localHash => $composableBuilder(
      column: $table.localHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteHash => $composableBuilder(
      column: $table.remoteHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localVersionJson => $composableBuilder(
      column: $table.localVersionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteVersionJson => $composableBuilder(
      column: $table.remoteVersionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteDeviceId => $composableBuilder(
      column: $table.remoteDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get resolved => $composableBuilder(
      column: $table.resolved, builder: (column) => ColumnFilters(column));
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$MergeSpaceDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localHash => $composableBuilder(
      column: $table.localHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteHash => $composableBuilder(
      column: $table.remoteHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localVersionJson => $composableBuilder(
      column: $table.localVersionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteVersionJson => $composableBuilder(
      column: $table.remoteVersionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteDeviceId => $composableBuilder(
      column: $table.remoteDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get resolved => $composableBuilder(
      column: $table.resolved, builder: (column) => ColumnOrderings(column));
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$MergeSpaceDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get localHash =>
      $composableBuilder(column: $table.localHash, builder: (column) => column);

  GeneratedColumn<String> get remoteHash => $composableBuilder(
      column: $table.remoteHash, builder: (column) => column);

  GeneratedColumn<String> get localVersionJson => $composableBuilder(
      column: $table.localVersionJson, builder: (column) => column);

  GeneratedColumn<String> get remoteVersionJson => $composableBuilder(
      column: $table.remoteVersionJson, builder: (column) => column);

  GeneratedColumn<String> get remoteDeviceId => $composableBuilder(
      column: $table.remoteDeviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => column);

  GeneratedColumn<bool> get resolved =>
      $composableBuilder(column: $table.resolved, builder: (column) => column);
}

class $$SyncConflictsTableTableManager extends RootTableManager<
    _$MergeSpaceDatabase,
    $SyncConflictsTable,
    SyncConflict,
    $$SyncConflictsTableFilterComposer,
    $$SyncConflictsTableOrderingComposer,
    $$SyncConflictsTableAnnotationComposer,
    $$SyncConflictsTableCreateCompanionBuilder,
    $$SyncConflictsTableUpdateCompanionBuilder,
    (
      SyncConflict,
      BaseReferences<_$MergeSpaceDatabase, $SyncConflictsTable, SyncConflict>
    ),
    SyncConflict,
    PrefetchHooks Function()> {
  $$SyncConflictsTableTableManager(
      _$MergeSpaceDatabase db, $SyncConflictsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> relativePath = const Value.absent(),
            Value<String> localHash = const Value.absent(),
            Value<String> remoteHash = const Value.absent(),
            Value<String> localVersionJson = const Value.absent(),
            Value<String> remoteVersionJson = const Value.absent(),
            Value<String> remoteDeviceId = const Value.absent(),
            Value<DateTime> detectedAt = const Value.absent(),
            Value<bool> resolved = const Value.absent(),
          }) =>
              SyncConflictsCompanion(
            id: id,
            relativePath: relativePath,
            localHash: localHash,
            remoteHash: remoteHash,
            localVersionJson: localVersionJson,
            remoteVersionJson: remoteVersionJson,
            remoteDeviceId: remoteDeviceId,
            detectedAt: detectedAt,
            resolved: resolved,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String relativePath,
            required String localHash,
            required String remoteHash,
            required String localVersionJson,
            required String remoteVersionJson,
            required String remoteDeviceId,
            required DateTime detectedAt,
            Value<bool> resolved = const Value.absent(),
          }) =>
              SyncConflictsCompanion.insert(
            id: id,
            relativePath: relativePath,
            localHash: localHash,
            remoteHash: remoteHash,
            localVersionJson: localVersionJson,
            remoteVersionJson: remoteVersionJson,
            remoteDeviceId: remoteDeviceId,
            detectedAt: detectedAt,
            resolved: resolved,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncConflictsTableProcessedTableManager = ProcessedTableManager<
    _$MergeSpaceDatabase,
    $SyncConflictsTable,
    SyncConflict,
    $$SyncConflictsTableFilterComposer,
    $$SyncConflictsTableOrderingComposer,
    $$SyncConflictsTableAnnotationComposer,
    $$SyncConflictsTableCreateCompanionBuilder,
    $$SyncConflictsTableUpdateCompanionBuilder,
    (
      SyncConflict,
      BaseReferences<_$MergeSpaceDatabase, $SyncConflictsTable, SyncConflict>
    ),
    SyncConflict,
    PrefetchHooks Function()>;

class $MergeSpaceDatabaseManager {
  final _$MergeSpaceDatabase _db;
  $MergeSpaceDatabaseManager(this._db);
  $$MergeSpaceFilesTableTableManager get mergeSpaceFiles =>
      $$MergeSpaceFilesTableTableManager(_db, _db.mergeSpaceFiles);
  $$PairedDevicesTableTableManager get pairedDevices =>
      $$PairedDevicesTableTableManager(_db, _db.pairedDevices);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
}
