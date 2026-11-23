import 'dart:async';
import '../models/helmet_state.dart';
import '../models/sensor_data.dart';
import '../models/telemetry_data.dart';

/// IIoTService defines the contract for communication between the mobile app
/// and the Smart Safety Helmet hardware (ESP32).
///
/// Designed to seamlessly swap between [MockIoTService] (for exhibitions/demos)
/// and real Bluetooth/BLE/MQTT drivers in the hardware phase.
abstract class IIoTService {
  /// Stream of connection status, battery, and firmware state.
  Stream<HelmetState> get helmetStateStream;

  /// Stream of IR helmet switch, MQ-3 alcohol ppm, and ignition interlock relay.
  Stream<SensorData> get sensorDataStream;

  /// Stream of MPU6050 accelerometer, gyro tilt, and GPS coordinates.
  Stream<TelemetryData> get telemetryDataStream;

  /// Connect to the ESP32 IoT helmet.
  Future<bool> connect(String deviceAddress);

  /// Disconnect from the helmet.
  Future<void> disconnect();

  /// Send ignition relay command to ESP32:
  /// true = Unlock engine ignition, false = Lock/cut engine ignition.
  Future<bool> setIgnitionLock(bool unlock);

  /// Toggle helmet rear LED safety lights (for night riding mode).
  Future<bool> setNightSafetyLights(bool active);

  /// Trigger helmet acoustic buzzer or LED strobe.
  Future<void> sendAuditoryAlert({int durationMs = 1500});

  /// Trigger simulated crash / fall for exhibition demonstration.
  Future<void> triggerSimulatedCrash({double impactG = 6.8, double tiltDeg = 75.0});

  /// Toggle helmet worn state for demonstration.
  Future<void> toggleHelmetWorn(bool worn);

  /// Update alcohol ppm reading for demonstration.
  Future<void> setAlcoholPpm(double ppm);

  /// Force immediate query for updated GPS location fix.
  Future<bool> refreshGpsLocation();

  /// Clean up streams and timers.
  void dispose();
}
