import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/helmet_state.dart';
import '../models/sensor_data.dart';
import '../models/telemetry_data.dart';
import 'iot_service.dart';

/// Esp32RestService communicates with the physical ESP32 Smart Helmet
/// over Wi-Fi using standard HTTP REST API endpoints.
class Esp32RestService implements IIoTService {
  String ipAddress;
  int port;
  final Duration timeout;
  final Duration pollInterval;

  final _helmetStateController = StreamController<HelmetState>.broadcast();
  final _sensorDataController = StreamController<SensorData>.broadcast();
  final _telemetryDataController = StreamController<TelemetryData>.broadcast();

  Timer? _pollingTimer;
  HttpClient? _httpClient;

  late HelmetState _currentHelmetState;
  late SensorData _currentSensorData;
  late TelemetryData _currentTelemetryData;

  int _consecutiveFailures = 0;
  static const int maxRetriesBeforeDisconnect = 4;
  bool _isDisposed = false;

  Esp32RestService({
    this.ipAddress = '192.168.4.1',
    this.port = 80,
    this.timeout = const Duration(milliseconds: 3000),
    this.pollInterval = const Duration(milliseconds: 1000),
  }) {
    final now = DateTime.now();

    _currentHelmetState = HelmetState(
      connectionStatus: ConnectionStatus.disconnected,
      deviceName: 'ESP32_SmartHelmet_2.0',
      macAddress: 'Unresolved',
      batteryLevel: 0,
      signalStrengthRssi: 0,
      lastSyncTime: now,
      firmwareVersion: 'Pending Connect',
      isSimulated: false,
    );

    _currentSensorData = SensorData(timestamp: now);
    _currentTelemetryData = TelemetryData(timestamp: now);

    _httpClient = HttpClient()..connectionTimeout = timeout;
  }

  String get baseUrl => 'http://$ipAddress:$port';

  @override
  Stream<HelmetState> get helmetStateStream => _helmetStateController.stream;

  @override
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;

  @override
  Stream<TelemetryData> get telemetryDataStream => _telemetryDataController.stream;

  void updateHost(String newIp, {int? newPort}) {
    ipAddress = newIp.trim();
    if (newPort != null) port = newPort;
  }

  @override
  Future<bool> connect(String deviceAddress) async {
    // Parse IP and port if provided as "192.168.4.1:80" or "192.168.4.1"
    if (deviceAddress.contains(':')) {
      final parts = deviceAddress.split(':');
      ipAddress = parts[0].trim();
      port = int.tryParse(parts[1].trim()) ?? 80;
    } else if (deviceAddress.isNotEmpty) {
      ipAddress = deviceAddress.trim();
    }

    _currentHelmetState = _currentHelmetState.copyWith(
      connectionStatus: ConnectionStatus.connecting,
      isSimulated: false,
    );
    _emitHelmetState();

    try {
      // 1. Initial Handshake via GET /api/status
      final statusJson = await _getJson('/api/status');

      if (statusJson != null) {
        _consecutiveFailures = 0;
        final now = DateTime.now();

        _currentHelmetState = HelmetState(
          connectionStatus: ConnectionStatus.connected,
          deviceName: statusJson['device_name']?.toString() ?? 'ESP32_SmartHelmet_2.0',
          macAddress: statusJson['mac_address']?.toString() ?? '24:6F:28:B3:7A:9C',
          batteryLevel: (statusJson['battery_level'] as num?)?.toInt() ?? 100,
          signalStrengthRssi: (statusJson['wifi_rssi'] as num?)?.toInt() ?? -60,
          firmwareVersion: statusJson['firmware_version']?.toString() ?? 'v2.1.0-Release',
          nightModeLightsActive: statusJson['night_lights_active'] == true,
          lastSyncTime: now,
          isSimulated: false,
        );
        _emitHelmetState();

        _startPeriodicPolling();
        return true;
      } else {
        _handleConnectionFailure('ESP32 returned empty response from /api/status');
        return false;
      }
    } catch (e) {
      _handleConnectionFailure('Connection failed: ${e.toString()}');
      return false;
    }
  }

  void _handleConnectionFailure(String reason) {
    _consecutiveFailures++;
    if (_consecutiveFailures >= maxRetriesBeforeDisconnect) {
      _pollingTimer?.cancel();
      _currentHelmetState = _currentHelmetState.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
      );
    } else {
      _currentHelmetState = _currentHelmetState.copyWith(
        connectionStatus: ConnectionStatus.reconnecting,
      );
    }
    _emitHelmetState();
  }

  void _startPeriodicPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollInterval, (timer) async {
      if (_isDisposed) return;
      await _pollAllTelemetry();
    });
  }

  Future<void> _pollAllTelemetry() async {
    try {
      // Fetch sensors and location concurrently
      final futures = await Future.wait([
        _getJson('/api/sensors'),
        _getJson('/api/location'),
        _getJson('/api/status'),
      ]);

      final sensorJson = futures[0];
      final locationJson = futures[1];
      final statusJson = futures[2];

      final now = DateTime.now();

      if (sensorJson != null) {
        _currentSensorData = SensorData(
          isHelmetWorn: sensorJson['helmet_worn'] == true,
          isStrapBuckled: sensorJson['buckle_latched'] ?? sensorJson['helmet_worn'] == true,
          alcoholPpm: (sensorJson['alcohol_ppm'] as num?)?.toDouble() ?? 0.0,
          isIgnitionUnlocked: sensorJson['ignition_unlocked'] == true,
          temperatureCelsius: (sensorJson['temperature_c'] as num?)?.toDouble() ?? 28.0,
          humidityPercent: (sensorJson['humidity_pct'] as num?)?.toDouble() ?? 50.0,
          timestamp: now,
        );
        if (!_sensorDataController.isClosed) {
          _sensorDataController.add(_currentSensorData);
        }
      }

      if (locationJson != null) {
        final rawLat = (locationJson['latitude'] as num?)?.toDouble();
        final rawLng = (locationJson['longitude'] as num?)?.toDouble();
        final sats = (locationJson['satellites'] as num?)?.toInt() ?? 0;
        final isValid = rawLat != null && rawLng != null && !(rawLat == 0.0 && rawLng == 0.0) && sats > 0;

        _currentTelemetryData = TelemetryData(
          speedKmh: (locationJson['speed_kmh'] as num?)?.toDouble() ?? 0.0,
          accelX: (locationJson['accel_x'] as num?)?.toDouble() ?? 0.0,
          accelY: (locationJson['accel_y'] as num?)?.toDouble() ?? 0.0,
          accelZ: (locationJson['accel_z'] as num?)?.toDouble() ?? 9.8,
          pitchAngle: (locationJson['pitch_deg'] as num?)?.toDouble() ?? 0.0,
          rollAngle: (locationJson['roll_deg'] as num?)?.toDouble() ?? 0.0,
          latitude: rawLat ?? 0.0,
          longitude: rawLng ?? 0.0,
          altitudeMeters: (locationJson['altitude_m'] as num?)?.toDouble() ?? 0.0,
          headingDegrees: (locationJson['heading_deg'] as num?)?.toDouble() ?? 0.0,
          gpsSatellites: sats,
          isImpactDetected: locationJson['impact_detected'] == true,
          lastImpactForceG: (locationJson['impact_force_g'] as num?)?.toDouble() ?? 1.0,
          tripDistanceKm: (locationJson['trip_distance_km'] as num?)?.toDouble() ?? _currentTelemetryData.tripDistanceKm,
          tripDurationSeconds: (locationJson['trip_duration_sec'] as num?)?.toInt() ?? _currentTelemetryData.tripDurationSeconds,
          maxSpeedKmh: (locationJson['max_speed_kmh'] as num?)?.toDouble() ?? _currentTelemetryData.maxSpeedKmh,
          timestamp: now,
          isRealHardware: true,
          isGpsFixValid: isValid,
        );
        if (!_telemetryDataController.isClosed) {
          _telemetryDataController.add(_currentTelemetryData);
        }
      }

      if (statusJson != null) {
        _consecutiveFailures = 0;
        _currentHelmetState = _currentHelmetState.copyWith(
          connectionStatus: ConnectionStatus.connected,
          batteryLevel: (statusJson['battery_level'] as num?)?.toInt() ?? _currentHelmetState.batteryLevel,
          signalStrengthRssi: (statusJson['wifi_rssi'] as num?)?.toInt() ?? _currentHelmetState.signalStrengthRssi,
          nightModeLightsActive: statusJson['night_lights_active'] == true,
          lastSyncTime: now,
        );
        _emitHelmetState();
      }
    } catch (e) {
      _handleConnectionFailure(e.toString());
    }
  }

  // --- REST HTTP Primitive Methods ---

  Future<Map<String, dynamic>?> _getJson(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await _httpClient!.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _postJson(String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await _httpClient!.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Ping diagnostic method for UI testing
  Future<Map<String, dynamic>> testConnection(String ip, int targetPort) async {
    final sw = Stopwatch()..start();
    final testUrl = 'http://$ip:$targetPort/api/status';

    try {
      final uri = Uri.parse(testUrl);
      final request = await _httpClient!.getUrl(uri).timeout(const Duration(milliseconds: 2500));
      final response = await request.close().timeout(const Duration(milliseconds: 2500));
      sw.stop();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        return {
          'success': true,
          'latency_ms': sw.elapsedMilliseconds,
          'statusCode': response.statusCode,
          'data': json,
        };
      } else {
        return {
          'success': false,
          'latency_ms': sw.elapsedMilliseconds,
          'error': 'HTTP Status ${response.statusCode}',
        };
      }
    } catch (e) {
      sw.stop();
      return {
        'success': false,
        'latency_ms': sw.elapsedMilliseconds,
        'error': e.toString(),
      };
    }
  }

  @override
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    _currentHelmetState = _currentHelmetState.copyWith(
      connectionStatus: ConnectionStatus.disconnected,
    );
    _emitHelmetState();
  }

  @override
  Future<bool> setIgnitionLock(bool unlock) async {
    final success = await _postJson('/api/ignition', {'unlock': unlock});
    if (success) {
      _currentSensorData = _currentSensorData.copyWith(isIgnitionUnlocked: unlock);
      _sensorDataController.add(_currentSensorData);
    }
    return success;
  }

  @override
  Future<bool> setNightSafetyLights(bool active) async {
    final success = await _postJson('/api/lights', {'active': active});
    if (success) {
      _currentHelmetState = _currentHelmetState.copyWith(nightModeLightsActive: active);
      _emitHelmetState();
    }
    return success;
  }

  @override
  Future<void> sendAuditoryAlert({int durationMs = 1500}) async {
    await _postJson('/api/buzzer', {'duration_ms': durationMs});
  }

  /// POST /api/sos triggers physical buzzer and GSM emergency SMS on ESP32
  Future<bool> triggerRemoteSos({
    required double latitude,
    required double longitude,
    required double impactG,
  }) async {
    return await _postJson('/api/sos', {
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'impact_g': impactG,
      'alert_type': 'CRASH_SOS',
    });
  }

  @override
  Future<void> triggerSimulatedCrash({double impactG = 6.8, double tiltDeg = 75.0}) async {
    // When connected to ESP32, notify device or trigger SOS
    await triggerRemoteSos(
      latitude: _currentTelemetryData.latitude,
      longitude: _currentTelemetryData.longitude,
      impactG: impactG,
    );
  }

  @override
  Future<void> toggleHelmetWorn(bool worn) async {
    // Forward command to hardware test stub if supported
    await _postJson('/api/test/helmet', {'worn': worn});
  }

  @override
  Future<void> setAlcoholPpm(double ppm) async {
    await _postJson('/api/test/alcohol', {'ppm': ppm});
  }

  @override
  Future<bool> refreshGpsLocation() async {
    try {
      final json = await _getJson('/api/location');
      if (json != null) {
        final now = DateTime.now();
        final rawLat = (json['latitude'] as num?)?.toDouble();
        final rawLng = (json['longitude'] as num?)?.toDouble();
        final sats = (json['satellites'] as num?)?.toInt() ?? 0;
        final isValid = rawLat != null && rawLng != null && !(rawLat == 0.0 && rawLng == 0.0) && sats > 0;

        _currentTelemetryData = _currentTelemetryData.copyWith(
          speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? _currentTelemetryData.speedKmh,
          latitude: rawLat ?? _currentTelemetryData.latitude,
          longitude: rawLng ?? _currentTelemetryData.longitude,
          gpsSatellites: sats,
          isGpsFixValid: isValid,
          timestamp: now,
          isRealHardware: true,
        );
        _telemetryDataController.add(_currentTelemetryData);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _emitHelmetState() {
    if (!_helmetStateController.isClosed) {
      _helmetStateController.add(_currentHelmetState);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _httpClient?.close(force: true);
    _helmetStateController.close();
    _sensorDataController.close();
    _telemetryDataController.close();
  }
}
