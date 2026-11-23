import '../constants/app_constants.dart';

enum GsmStatus {
  registered,
  searching,
  noSim,
  error,
}

enum AlcoholLevel { safe, moderate, danger }

/// Captures safety sensors data from the helmet's IR, MQ-3, MPU6050, and SIM800L GSM.
/// Explicitly tracks whether data originates from physical hardware or demo simulation.
class SensorData {
  final bool isHelmetWorn;
  final bool isStrapBuckled;
  final double alcoholPpm;
  final double alcoholThresholdPpm;
  final bool isIgnitionUnlocked; // Controlled by ESP32 Relay
  final double temperatureCelsius;
  final double humidityPercent;
  final DateTime timestamp;

  // Real Hardware vs Demo Simulation Provenance
  final bool isRealHardware;
  final bool isAlcoholSimulated;
  final bool isAlcoholCalibrating;

  // Sensor Peripheral Health & Connection Status
  final bool isIrSensorOnline;
  final bool isMpu6050Online;
  final GsmStatus gsmStatus;
  final int gsmSignalBars; // 0 - 5
  final String gsmOperator;

  const SensorData({
    this.isHelmetWorn = true,
    this.isStrapBuckled = true,
    this.alcoholPpm = 45.0,
    this.alcoholThresholdPpm = AppConstants.alcoholSafetyThresholdPpm,
    this.isIgnitionUnlocked = true,
    this.temperatureCelsius = 28.4,
    this.humidityPercent = 54.0,
    required this.timestamp,
    this.isRealHardware = false,
    this.isAlcoholSimulated = true,
    this.isAlcoholCalibrating = false,
    this.isIrSensorOnline = true,
    this.isMpu6050Online = true,
    this.gsmStatus = GsmStatus.registered,
    this.gsmSignalBars = 4,
    this.gsmOperator = 'Airtel / SIM800L Ready',
  });

  /// True if alcohol reading is below dangerous threshold.
  bool get isAlcoholSafe => alcoholPpm < alcoholThresholdPpm;

  /// Full rider safety checklist passes only if worn AND sober.
  bool get isSafetyCompliant => isHelmetWorn && isAlcoholSafe;

  /// Alcohol danger severity level for UI color cues.
  AlcoholLevel get alcoholLevel {
    if (alcoholPpm < 100) return AlcoholLevel.safe;
    if (alcoholPpm < alcoholThresholdPpm) return AlcoholLevel.moderate;
    return AlcoholLevel.danger;
  }

  SensorData copyWith({
    bool? isHelmetWorn,
    bool? isStrapBuckled,
    double? alcoholPpm,
    double? alcoholThresholdPpm,
    bool? isIgnitionUnlocked,
    double? temperatureCelsius,
    double? humidityPercent,
    DateTime? timestamp,
    bool? isRealHardware,
    bool? isAlcoholSimulated,
    bool? isAlcoholCalibrating,
    bool? isIrSensorOnline,
    bool? isMpu6050Online,
    GsmStatus? gsmStatus,
    int? gsmSignalBars,
    String? gsmOperator,
  }) {
    return SensorData(
      isHelmetWorn: isHelmetWorn ?? this.isHelmetWorn,
      isStrapBuckled: isStrapBuckled ?? this.isStrapBuckled,
      alcoholPpm: alcoholPpm ?? this.alcoholPpm,
      alcoholThresholdPpm: alcoholThresholdPpm ?? this.alcoholThresholdPpm,
      isIgnitionUnlocked: isIgnitionUnlocked ?? this.isIgnitionUnlocked,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      timestamp: timestamp ?? this.timestamp,
      isRealHardware: isRealHardware ?? this.isRealHardware,
      isAlcoholSimulated: isAlcoholSimulated ?? this.isAlcoholSimulated,
      isAlcoholCalibrating: isAlcoholCalibrating ?? this.isAlcoholCalibrating,
      isIrSensorOnline: isIrSensorOnline ?? this.isIrSensorOnline,
      isMpu6050Online: isMpu6050Online ?? this.isMpu6050Online,
      gsmStatus: gsmStatus ?? this.gsmStatus,
      gsmSignalBars: gsmSignalBars ?? this.gsmSignalBars,
      gsmOperator: gsmOperator ?? this.gsmOperator,
    );
  }
}
