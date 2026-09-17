import 'device.dart';

enum DiscoveryStatus {
  idle,
  scanning,
  error,
}

class DiscoveryState {
  final DiscoveryStatus status;
  final List<Device> devices;
  final String? errorMessage;
  final bool isBroadcasting;
  final Device? localDevice;

  const DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.devices = const [],
    this.errorMessage,
    this.isBroadcasting = false,
    this.localDevice,
  });

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<Device>? devices,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isBroadcasting,
    Device? localDevice,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      localDevice: localDevice ?? this.localDevice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          isBroadcasting == other.isBroadcasting &&
          localDevice == other.localDevice &&
          _listEquals(devices, other.devices);

  @override
  int get hashCode => Object.hash(
        status,
        Object.hashAll(devices),
        errorMessage,
        isBroadcasting,
        localDevice,
      );

  static bool _listEquals(List<Device> a, List<Device> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
