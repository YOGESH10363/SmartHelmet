/// AppConstants holds system thresholds, hardware defaults, and exhibition metadata.
class AppConstants {
  // App Branding
  static const String appName = 'Smart Helmet 2.0';
  static const String appVersion = 'v2.0.4';
  static const String projectTagline = 'IoT-Based Intelligent Safety & Telemetry System';
  static const String exhibitionName = 'Academic Innovation & Technology Exhibition 2026';

  // Sensor Thresholds (for ESP32 and Simulation)
  static const double alcoholSafetyThresholdPpm = 200.0; // MQ-3 Alcohol threshold
  static const double alcoholDangerousPpm = 450.0;
  static const double gForceAccidentThreshold = 4.2;      // MPU6050 fall/crash G threshold
  static const double tiltAngleAccidentThreshold = 65.0; // Degrees tilt from vertical
  static const double overSpeedLimitKmh = 80.0;          // Speed limit warning

  // Emergency SOS Defaults
  static const int defaultSosCountdownSeconds = 10;
  static const String defaultEmergencyNumber = '112';

  // ESP32 Bluetooth Constants
  static const String defaultBleDeviceName = 'ESP32_SmartHelmet_2.0';
  static const String defaultBleServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String defaultBleCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  // Team & Exhibition Metadata
  static const String teamSupervisor = 'Dr. R. K. Sharma (Dept. of IoT & Embedded Systems)';
  static const String collegeName = 'Apex Institute of Technology & Engineering';
  static const List<String> teamMembers = [
    'Yogesh (Lead Developer & IoT Architect)',
    'Engineering Team (Hardware & Sensor Integration)',
  ];

  static const List<String> hardwareSpecs = [
    'ESP32 Dual-Core 240MHz Microcontroller (FreeRTOS)',
    'MQ-3 Sensitive Alcohol Gas Sensor with Fast Preheating',
    'MPU6050 6-Axis Accelerometer & Gyroscope (Fall Detection)',
    'Helmet IR Proximity Sensor & Buckle Switch',
    'NEO-6M High-Precision GPS Module',
    'SIM800L Quad-Band GSM/GPRS Module (Emergency SMS)',
    '12V High-Amperage Engine Ignition Cut-Off Relay',
    'High-Lumen Night Safety Helmet LED Warning Array',
    '3.7V 2500mAh LiPo Battery with TP4056 BMS Protection',
  ];
}
