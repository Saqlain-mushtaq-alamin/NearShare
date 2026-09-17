class Device {
  final String id;
  final String name;
  final String platform;
  final String ipAddress;
  final int port;
  final DateTime discoveredAt;

  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.ipAddress,
    required this.port,
    required this.discoveredAt,
  });

  Device copyWith({
    String? id,
    String? name,
    String? platform,
    String? ipAddress,
    int? port,
    DateTime? discoveredAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'ipAddress': ipAddress,
      'port': port,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Device',
      platform: json['platform'] as String? ?? 'unknown',
      ipAddress: json['ipAddress'] as String? ?? '',
      port: json['port'] as int? ?? 53317,
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.tryParse(json['discoveredAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          platform == other.platform &&
          ipAddress == other.ipAddress &&
          port == other.port;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      platform.hashCode ^
      ipAddress.hashCode ^
      port.hashCode;

  @override
  String toString() {
    return 'Device(id: $id, name: $name, platform: $platform, ipAddress: $ipAddress, port: $port)';
  }
}
