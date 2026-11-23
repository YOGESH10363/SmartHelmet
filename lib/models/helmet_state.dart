/// Connection states of the IoT Smart Helmet device.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  scanning,
  error,
}

/// Represents the overall status and connectivity of the ESP32 Smart Helmet.
class HelmetState {
  final ConnectionStatus connectionStatus;
  final String deviceName;
  final String macAddress;
  final int batteryLevel; // 0 - 100%
  final int signalStrengthRssi; // dBm e.g. -65
  final bool isCharging;
  final DateTime lastSyncTime;
  final String firmwareVersion;
  final bool nightModeLightsActive;
  final bool isSimulated;

  const HelmetState({
    this.connectionStatus = ConnectionStatus.connected,
    this.deviceName = 'ESP32_SmartHelmet_2.0',
    this.macAddress = '24:6F:28:B3:7A:9C',
    this.batteryLevel = 88,
    this.signalStrengthRssi = -58,
    this.isCharging = false,
    required this.lastSyncTime,
    this.firmwareVersion = 'v2.1.0-Release',
    this.nightModeLightsActive = false,
    this.isSimulated = true,
  });

  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  HelmetState copyWith({
    ConnectionStatus? connectionStatus,
    String? deviceName,
    String? macAddress,
    int? batteryLevel,
    int? signalStrengthRssi,
    bool? isCharging,
    DateTime? lastSyncTime,
    String? firmwareVersion,
    bool? nightModeLightsActive,
    bool? isSimulated,
  }) {
    return HelmetState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      deviceName: deviceName ?? this.deviceName,
      macAddress: macAddress ?? this.macAddress,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrengthRssi: signalStrengthRssi ?? this.signalStrengthRssi,
      isCharging: isCharging ?? this.isCharging,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      nightModeLightsActive: nightModeLightsActive ?? this.nightModeLightsActive,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }
}
