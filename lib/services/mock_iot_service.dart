import 'dart:async';
import 'dart:math';
import '../models/helmet_state.dart';
import '../models/sensor_data.dart';
import '../models/telemetry_data.dart';
import 'iot_service.dart';

/// MockIoTService generates realistic real-time telemetry simulating
/// an ESP32 microcontroller with MPU6050, MQ-3, and GPS modules.
class MockIoTService implements IIoTService {
  final _helmetStateController = StreamController<HelmetState>.broadcast();
  final _sensorDataController = StreamController<SensorData>.broadcast();
  final _telemetryDataController = StreamController<TelemetryData>.broadcast();

  Timer? _telemetryTimer;
  final Random _random = Random();

  // Internal mutable states
  late HelmetState _currentHelmetState;
  late SensorData _currentSensorData;
  late TelemetryData _currentTelemetryData;

  bool _isDisposed = false;

  MockIoTService() {
    final now = DateTime.now();

    _currentHelmetState = HelmetState(
      connectionStatus: ConnectionStatus.connected,
      deviceName: 'ESP32_SmartHelmet_2.0',
      macAddress: '24:6F:28:B3:7A:9C',
      batteryLevel: 92,
      signalStrengthRssi: -54,
      isCharging: false,
      lastSyncTime: now,
      firmwareVersion: 'v2.1.0-ESP32',
      nightModeLightsActive: false,
      isSimulated: true,
    );

    _currentSensorData = SensorData(
      isHelmetWorn: true,
      isStrapBuckled: true,
      alcoholPpm: 38.5,
      isIgnitionUnlocked: true,
      temperatureCelsius: 29.1,
      humidityPercent: 52.0,
      timestamp: now,
    );

    _currentTelemetryData = TelemetryData(
      speedKmh: 41.2,
      accelX: 0.15,
      accelY: -0.08,
      accelZ: 9.81,
      pitchAngle: 3.2,
      rollAngle: -1.8,
      latitude: 18.5204,
      longitude: 73.8567,
      altitudeMeters: 562.0,
      headingDegrees: 48.0,
      gpsSatellites: 9,
      isImpactDetected: false,
      lastImpactForceG: 1.02,
      tripDistanceKm: 12.4,
      tripDurationSeconds: 1420,
      maxSpeedKmh: 64.0,
      timestamp: now,
    );

    _startTelemetryLoop();
  }

  @override
  Stream<HelmetState> get helmetStateStream => _helmetStateController.stream;

  @override
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;

  @override
  Stream<TelemetryData> get telemetryDataStream => _telemetryDataController.stream;

  void _startTelemetryLoop() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_isDisposed) return;
      _tickTelemetry();
    });
  }

  void _tickTelemetry() {
    if (!_currentHelmetState.isConnected) return;

    final now = DateTime.now();

    // 1. Telemetry jitter & smooth progression
    double newSpeed = _currentTelemetryData.speedKmh;
    // Vary speed smoothly if moving
    if (newSpeed > 0) {
      final delta = (_random.nextDouble() * 3.0) - 1.4;
      newSpeed = (newSpeed + delta).clamp(28.0, 68.0);
    }

    final double maxSpeed = max(_currentTelemetryData.maxSpeedKmh, newSpeed);
    final double addedDistance = (newSpeed / 3600.0); // km in 1 sec
    final double newDistance = _currentTelemetryData.tripDistanceKm + addedDistance;
    final int newDuration = _currentTelemetryData.tripDurationSeconds + 1;

    // Small GPS latitude drift
    final double newLat = _currentTelemetryData.latitude + (0.00002 * (newSpeed / 40.0));
    final double newLng = _currentTelemetryData.longitude + (0.000015 * (newSpeed / 40.0));

    // Natural motion vibrations
    final double accelNoiseX = (_random.nextDouble() * 0.4) - 0.2;
    final double accelNoiseY = (_random.nextDouble() * 0.4) - 0.2;
    final double pitchNoise = (_random.nextDouble() * 1.5) - 0.75;
    final double rollNoise = (_random.nextDouble() * 1.5) - 0.75;

    _currentTelemetryData = _currentTelemetryData.copyWith(
      speedKmh: double.parse(newSpeed.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(maxSpeed.toStringAsFixed(1)),
      tripDistanceKm: double.parse(newDistance.toStringAsFixed(2)),
      tripDurationSeconds: newDuration,
      accelX: double.parse(accelNoiseX.toStringAsFixed(2)),
      accelY: double.parse(accelNoiseY.toStringAsFixed(2)),
      accelZ: 9.81 + ((_random.nextDouble() * 0.2) - 0.1),
      pitchAngle: double.parse((3.0 + pitchNoise).toStringAsFixed(1)),
      rollAngle: double.parse((-1.5 + rollNoise).toStringAsFixed(1)),
      latitude: newLat,
      longitude: newLng,
      timestamp: now,
      isImpactDetected: false, // Reset single-pulse impact
    );

    // 2. Sensor slight fluctuations
    final double alcoholFluctuation = (_random.nextDouble() * 2.0) - 1.0;
    final double newAlcohol = (_currentSensorData.alcoholPpm + alcoholFluctuation).clamp(10.0, 600.0);

    // Evaluate auto ignition interlock logic
    final bool safetyPassed = _currentSensorData.isHelmetWorn && (newAlcohol < _currentSensorData.alcoholThresholdPpm);

    _currentSensorData = _currentSensorData.copyWith(
      alcoholPpm: double.parse(newAlcohol.toStringAsFixed(1)),
      isIgnitionUnlocked: safetyPassed,
      timestamp: now,
    );

    // 3. Helmet connection pulse
    final int rssiDrift = (_random.nextInt(5) - 2);
    _currentHelmetState = _currentHelmetState.copyWith(
      signalStrengthRssi: (_currentHelmetState.signalStrengthRssi + rssiDrift).clamp(-85, -45),
      lastSyncTime: now,
    );

    // Broadcast updates
    if (!_helmetStateController.isClosed) {
      _helmetStateController.add(_currentHelmetState);
    }
    if (!_sensorDataController.isClosed) {
      _sensorDataController.add(_currentSensorData);
    }
    if (!_telemetryDataController.isClosed) {
      _telemetryDataController.add(_currentTelemetryData);
    }
  }

  @override
  Future<bool> connect(String deviceAddress) async {
    _currentHelmetState = _currentHelmetState.copyWith(
      connectionStatus: ConnectionStatus.connecting,
    );
    _helmetStateController.add(_currentHelmetState);

    await Future.delayed(const Duration(milliseconds: 900));

    _currentHelmetState = _currentHelmetState.copyWith(
      connectionStatus: ConnectionStatus.connected,
      deviceName: 'ESP32_SmartHelmet_2.0',
      lastSyncTime: DateTime.now(),
    );
    _helmetStateController.add(_currentHelmetState);
    _startTelemetryLoop();
    return true;
  }

  @override
  Future<void> disconnect() async {
    _telemetryTimer?.cancel();
    _currentHelmetState = _currentHelmetState.copyWith(
      connectionStatus: ConnectionStatus.disconnected,
    );
    _helmetStateController.add(_currentHelmetState);
  }

  @override
  Future<bool> setIgnitionLock(bool unlock) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentSensorData = _currentSensorData.copyWith(
      isIgnitionUnlocked: unlock,
    );
    _sensorDataController.add(_currentSensorData);
    return true;
  }

  @override
  Future<bool> setNightSafetyLights(bool active) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentHelmetState = _currentHelmetState.copyWith(
      nightModeLightsActive: active,
    );
    _helmetStateController.add(_currentHelmetState);
    return true;
  }

  @override
  Future<void> sendAuditoryAlert({int durationMs = 1500}) async {
    await Future.delayed(Duration(milliseconds: min(durationMs, 500)));
  }

  @override
  Future<void> triggerSimulatedCrash({double impactG = 6.8, double tiltDeg = 75.0}) async {
    final now = DateTime.now();
    _currentTelemetryData = _currentTelemetryData.copyWith(
      isImpactDetected: true,
      lastImpactForceG: impactG,
      pitchAngle: tiltDeg,
      rollAngle: 45.0,
      speedKmh: 0.0, // Bike halts on crash
      timestamp: now,
    );
    _telemetryDataController.add(_currentTelemetryData);
  }

  @override
  Future<void> toggleHelmetWorn(bool worn) async {
    final now = DateTime.now();
    final bool safetyPassed = worn && _currentSensorData.isAlcoholSafe;

    _currentSensorData = _currentSensorData.copyWith(
      isHelmetWorn: worn,
      isStrapBuckled: worn,
      isIgnitionUnlocked: safetyPassed,
      timestamp: now,
    );
    _sensorDataController.add(_currentSensorData);
  }

  @override
  Future<void> setAlcoholPpm(double ppm) async {
    final now = DateTime.now();
    final bool safetyPassed = _currentSensorData.isHelmetWorn && (ppm < _currentSensorData.alcoholThresholdPpm);

    _currentSensorData = _currentSensorData.copyWith(
      alcoholPpm: ppm,
      isIgnitionUnlocked: safetyPassed,
      timestamp: now,
    );
    _sensorDataController.add(_currentSensorData);
  }

  @override
  Future<bool> refreshGpsLocation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    _currentTelemetryData = _currentTelemetryData.copyWith(
      timestamp: now,
      gpsSatellites: 9,
      isGpsFixValid: true,
    );
    _telemetryDataController.add(_currentTelemetryData);
    return true;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _telemetryTimer?.cancel();
    _helmetStateController.close();
    _sensorDataController.close();
    _telemetryDataController.close();
  }
}
