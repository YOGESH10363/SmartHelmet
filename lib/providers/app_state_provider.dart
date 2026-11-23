import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../models/emergency_contact.dart';
import '../models/helmet_event_record.dart';
import '../models/helmet_state.dart';
import '../models/incident_report.dart';
import '../models/sensor_data.dart';
import '../models/telemetry_data.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/emergency_service.dart';
import '../services/esp32_rest_service.dart';
import '../services/iot_service.dart';
import '../services/mock_iot_service.dart';
import '../services/notification_service.dart';
import '../services/report_export_service.dart';
import '../services/sqflite_adapter.dart';
import '../services/storage_service.dart';

/// AppStateProvider acts as the central reactive brain for Smart Helmet 2.0.
/// Supports both physical ESP32 Wi-Fi REST API integration and Exhibition Demo Mode.
class AppStateProvider extends ChangeNotifier {
  late IIoTService _activeIotService;
  late final MockIoTService _mockService;
  late final Esp32RestService _esp32RestService;
  final EmergencyService _emergencyService;
  final StorageService _storageService;
  final DatabaseService _databaseService = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final ReportExportService _reportExportService = ReportExportService.instance;

  bool _isDemoMode = true;
  String _esp32IpAddress = '192.168.4.1';
  int _esp32Port = 80;

  late HelmetState _helmetState;
  late SensorData _sensorData;
  late TelemetryData _telemetryData;

  // Transition state tracking to prevent duplicate spam in SQLite
  bool? _lastHelmetWorn;
  ConnectionStatus? _lastConnectionStatus;
  bool _lastAlcoholLimitExceeded = false;
  DateTime? _lastGpsLoggedTime;
  bool? _lastGpsSignal;

  StreamSubscription<HelmetState>? _helmetSub;
  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<TelemetryData>? _telemetrySub;
  StreamSubscription<int>? _sosCountdownSub;
  StreamSubscription<IncidentReport>? _emergencyDispatchedSub;
  StreamSubscription<IncidentReport>? _emergencyStatusSub;

  IncidentReport? _activeEmergencyIncident;

  AppStateProvider({
    EmergencyService? emergencyService,
    StorageService? storageService,
  })  : _emergencyService = emergencyService ?? EmergencyService(),
        _storageService = storageService ?? StorageService() {
    _mockService = MockIoTService();
    _esp32RestService = Esp32RestService(ipAddress: _esp32IpAddress, port: _esp32Port);
    _activeIotService = _mockService; // Default to Demo mode for stable initial presentation

    _initDefaults();
    if (!kIsWeb) {
      _databaseService.init(customAdapter: SqfliteStorageAdapter());
    } else {
      _databaseService.init();
    }
    _subscribeToActiveIotStreams();
    _subscribeToEmergencyStreams();
  }

  void _initDefaults() {
    final now = DateTime.now();
    _helmetState = HelmetState(lastSyncTime: now, isSimulated: _isDemoMode);
    _sensorData = SensorData(timestamp: now);
    _telemetryData = TelemetryData(timestamp: now);
    _lastHelmetWorn = _sensorData.isHelmetWorn;
    _lastConnectionStatus = _helmetState.connectionStatus;
    _lastGpsSignal = _telemetryData.isGpsFixValid;
  }

  void _subscribeToActiveIotStreams() {
    _helmetSub?.cancel();
    _sensorSub?.cancel();
    _telemetrySub?.cancel();

    _helmetSub = _activeIotService.helmetStateStream.listen((state) {
      // 1. Detect connection status transitions
      if (_lastConnectionStatus != null && _lastConnectionStatus != state.connectionStatus) {
        if (state.connectionStatus == ConnectionStatus.connected) {
          _logConnectionEvent(
            title: 'ESP32 Wi-Fi Gateway Connected',
            desc: 'IoT telemetry channel established on $_esp32IpAddress:$_esp32Port. Sensor heartbeat verified.',
            severity: EventSeverity.info,
            status: 'connected',
          );
          _notificationService.notify(
            title: 'ESP32 Gateway Connected',
            body: 'Wi-Fi link established with ESP32 at $_esp32IpAddress:$_esp32Port.',
            severity: EventSeverity.info,
            isDemo: _isDemoMode,
          );
        } else if (state.connectionStatus == ConnectionStatus.disconnected) {
          _logConnectionEvent(
            title: 'ESP32 Wi-Fi Gateway Disconnected',
            desc: 'IoT telemetry link lost or polling timed out.',
            severity: EventSeverity.warning,
            status: 'disconnected',
          );
          _notificationService.notify(
            title: 'ESP32 Disconnected',
            body: 'Telemetry link lost. Reconnection in progress...',
            severity: EventSeverity.warning,
            isDemo: _isDemoMode,
          );
        }
      }
      _lastConnectionStatus = state.connectionStatus;

      _helmetState = state;
      notifyListeners();
    });

    _sensorSub = _activeIotService.sensorDataStream.listen((sensors) {
      // 2. Detect helmet wearing state transitions
      if (_lastHelmetWorn != null && _lastHelmetWorn != sensors.isHelmetWorn) {
        if (sensors.isHelmetWorn) {
          _logHelmetStatusEvent(
            title: 'Safety Helmet Fastened & Worn',
            desc: 'Optical IR proximity sensor engaged. 12V Ignition relay circuit ready.',
            severity: EventSeverity.info,
            status: 'interlock_unlocked',
          );
          _notificationService.notify(
            title: 'Safety Helmet Fastened',
            body: 'Optical sensor verified helmet is properly strapped.',
            severity: EventSeverity.info,
            isDemo: _isDemoMode,
          );
        } else {
          _logHelmetStatusEvent(
            title: 'Safety Warning: Helmet Removed',
            desc: 'Rider unfastened helmet. 12V Ignition relay circuit cut off.',
            severity: EventSeverity.warning,
            status: 'interlock_locked',
          );
          _notificationService.notify(
            title: 'Safety Warning: Helmet Removed',
            body: 'Helmet removed while vehicle active. Ignition cut off.',
            severity: EventSeverity.warning,
            isDemo: _isDemoMode,
          );
        }
      }
      _lastHelmetWorn = sensors.isHelmetWorn;

      // 3. Detect alcohol threshold exceeded transitions
      final isAlcoholAlert = !sensors.isAlcoholSafe;
      if (isAlcoholAlert && !_lastAlcoholLimitExceeded) {
        _logAlcoholEvent(sensors.alcoholPpm);
        _notificationService.notify(
          title: 'DUI Prevention Alert',
          body: 'Alcohol level ${sensors.alcoholPpm.toInt()} PPM exceeds 200 PPM limit! Ignition locked.',
          severity: EventSeverity.critical,
          isDemo: sensors.isAlcoholSimulated,
        );
      }
      _lastAlcoholLimitExceeded = isAlcoholAlert;

      _sensorData = sensors;
      notifyListeners();
    });

    _telemetrySub = _activeIotService.telemetryDataStream.listen((telemetry) {
      // 4. Detect GPS satellite lock transitions
      if (_lastGpsSignal != null && !_lastGpsSignal! && telemetry.isGpsFixValid) {
        _logGpsFixAcquired(telemetry);
        _notificationService.notify(
          title: 'GPS Satellite Fix Acquired',
          body: 'NEO-6M locked onto ${telemetry.gpsSatellites} satellites.',
          severity: EventSeverity.info,
          isDemo: _isDemoMode,
        );
      }
      _lastGpsSignal = telemetry.isGpsFixValid;

      // 5. Periodic trip GPS waypoint recording (every 90s when moving > 5 km/h)
      if (telemetry.speedKmh > 5.0 && telemetry.areCoordinatesValid) {
        final now = DateTime.now();
        if (_lastGpsLoggedTime == null || now.difference(_lastGpsLoggedTime!).inSeconds >= 90) {
          _lastGpsLoggedTime = now;
          _logGpsWaypoint(telemetry);
        }
      }

      // Automated fall / accident trigger check
      if (telemetry.isImpactDetected && !_emergencyService.isCountdownActive) {
        _handleAccidentDetected(telemetry);
      }

      _telemetryData = telemetry;
      notifyListeners();
    });
  }

  void _subscribeToEmergencyStreams() {
    _sosCountdownSub = _emergencyService.countdownStream.listen((remaining) {
      notifyListeners();
    });

    _emergencyDispatchedSub = _emergencyService.emergencyTriggeredStream.listen((report) {
      _storageService.addIncidentReport(report);
      _activeEmergencyIncident = report;

      // Update SQLite record status to dispatched/pending
      _databaseService.insertEvent(
        HelmetEventRecord(
          id: report.id,
          timestamp: report.timestamp,
          eventType: report.type == IncidentType.crashDetected
              ? HelmetEventType.accident
              : HelmetEventType.sos,
          title: report.title,
          description: report.description,
          severity: EventSeverity.critical,
          isDemo: _isDemoMode,
          latitude: report.latitude,
          longitude: report.longitude,
          speedKmh: report.speedKmh,
          gForce: report.peakGForce,
          status: 'pending_gsm_queue',
          metadata: {'deliveryStatus': report.deliveryStatus.name},
        ),
      );

      notifyListeners();
    });

    _emergencyStatusSub = _emergencyService.statusUpdatedStream.listen((report) {
      _activeEmergencyIncident = report;

      if (report.deliveryStatus == AlertDeliveryStatus.delivered) {
        _notificationService.notify(
          title: 'Distress Alert Delivered',
          body: 'GSM network confirmed SMS delivery (+CMGS ACK) to contacts.',
          severity: EventSeverity.info,
          isDemo: _isDemoMode,
        );
      } else if (report.deliveryStatus == AlertDeliveryStatus.acknowledged) {
        _notificationService.notify(
          title: 'Distress Alert Acknowledged',
          body: 'Incident confirmed resolved by ${report.acknowledgedBy ?? 'Rider'}.',
          severity: EventSeverity.info,
          isDemo: _isDemoMode,
        );
      }

      // Update in SQLite
      _databaseService.insertEvent(
        HelmetEventRecord(
          id: report.id,
          timestamp: report.timestamp,
          eventType: report.type == IncidentType.crashDetected
              ? HelmetEventType.accident
              : HelmetEventType.sos,
          title: report.title,
          description: report.description,
          severity: EventSeverity.critical,
          isDemo: _isDemoMode,
          latitude: report.latitude,
          longitude: report.longitude,
          speedKmh: report.speedKmh,
          gForce: report.peakGForce,
          status: report.deliveryStatus.name,
          metadata: {
            'acknowledgedBy': report.acknowledgedBy,
            'acknowledgedAt': report.acknowledgedAt?.toIso8601String(),
          },
        ),
      );

      notifyListeners();
    });
  }

  // --- Getters ---
  bool get isDemoMode => _isDemoMode;
  bool get isTestEmergencyMode => _emergencyService.isTestEmergencyMode;
  String get esp32IpAddress => _esp32IpAddress;
  int get esp32Port => _esp32Port;
  String get esp32BaseUrl => 'http://$_esp32IpAddress:$_esp32Port';

  HelmetState get helmetState => _helmetState;
  SensorData get sensorData => _sensorData;
  TelemetryData get telemetryData => _telemetryData;
  UserProfile get userProfile => _storageService.userProfile;
  List<EmergencyContact> get emergencyContacts => _storageService.emergencyContacts;
  List<IncidentReport> get incidentReports => _storageService.incidentReports;

  bool get isSosCountdownActive => _emergencyService.isCountdownActive;
  int get sosRemainingSeconds => _emergencyService.remainingSeconds;
  IncidentReport? get activeEmergencyIncident => _activeEmergencyIncident;

  int get sosCountdownDuration => _storageService.sosCountdownDuration;
  bool get soundAlertsEnabled => _storageService.soundAlertsEnabled;
  bool get simulationModeEnabled => _storageService.simulationModeEnabled;
  bool get autoNightModeEnabled => _storageService.autoNightModeEnabled;

  // --- ESP32 Wi-Fi & Demo Mode Switching ---

  /// Test connectivity to ESP32 IP before committing
  Future<Map<String, dynamic>> testEsp32Connection(String ip, int port) async {
    return await _esp32RestService.testConnection(ip, port);
  }

  /// Connect to physical ESP32 over Wi-Fi HTTP REST API
  Future<bool> connectToEsp32(String ip, {int port = 80}) async {
    _esp32IpAddress = ip.trim();
    _esp32Port = port;
    _isDemoMode = false;

    _esp32RestService.updateHost(_esp32IpAddress, newPort: _esp32Port);
    _activeIotService = _esp32RestService;
    _subscribeToActiveIotStreams();

    final success = await _esp32RestService.connect('$_esp32IpAddress:$_esp32Port');
    notifyListeners();
    return success;
  }

  /// Disconnect ESP32
  Future<void> disconnectEsp32() async {
    await _esp32RestService.disconnect();
    notifyListeners();
  }

  /// Switch to Exhibition Demo Mode
  void switchToDemoMode() {
    _isDemoMode = true;
    _esp32RestService.disconnect();
    _activeIotService = _mockService;
    _subscribeToActiveIotStreams();
    _mockService.connect('DEMO_MODE');
    notifyListeners();
  }

  // --- Hardware Commands ---

  Future<void> toggleIgnitionRelay(bool unlock) async {
    await _activeIotService.setIgnitionLock(unlock);
    notifyListeners();
  }

  Future<void> toggleNightLights(bool active) async {
    await _activeIotService.setNightSafetyLights(active);
    notifyListeners();
  }

  Future<void> toggleHelmetWorn(bool worn) async {
    await _activeIotService.toggleHelmetWorn(worn);
    notifyListeners();
  }

  Future<void> setAlcoholPpm(double ppm) async {
    await _activeIotService.setAlcoholPpm(ppm);
    notifyListeners();
  }

  Future<bool> refreshGpsLocation() async {
    final result = await _activeIotService.refreshGpsLocation();
    if (result && _telemetryData.areCoordinatesValid) {
      _databaseService.insertEvent(
        HelmetEventRecord(
          id: 'GPS-REFRESH-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          eventType: HelmetEventType.gpsUpdate,
          title: 'GPS Position Refreshed',
          description: 'Position manually synchronized: ${_telemetryData.latitude.toStringAsFixed(4)}, ${_telemetryData.longitude.toStringAsFixed(4)} (Satellites: ${_telemetryData.gpsSatellites})',
          severity: EventSeverity.info,
          isDemo: _isDemoMode,
          latitude: _telemetryData.latitude,
          longitude: _telemetryData.longitude,
          speedKmh: _telemetryData.speedKmh,
          status: 'refreshed',
        ),
      );
    }
    notifyListeners();
    return result;
  }

  /// Exhibition demonstration: trigger crash impact
  Future<void> triggerSimulatedCrash() async {
    await _activeIotService.triggerSimulatedCrash();
  }

  void _handleAccidentDetected(TelemetryData telemetry) {
    final incident = IncidentReport(
      id: 'ACC-${DateTime.now().millisecondsSinceEpoch}',
      type: IncidentType.crashDetected,
      severity: IncidentSeverity.critical,
      title: 'Crash Impact Registered (${telemetry.lastImpactForceG} G)',
      description: 'Vehicle impact of ${telemetry.lastImpactForceG} G detected with helmet tilt angle of ${telemetry.pitchAngle.abs()}° at ${telemetry.speedKmh} km/h.',
      latitude: telemetry.latitude,
      longitude: telemetry.longitude,
      speedKmh: telemetry.speedKmh,
      peakGForce: telemetry.lastImpactForceG,
      timestamp: DateTime.now(),
    );

    _activeEmergencyIncident = incident;

    // Log to SQLite
    _databaseService.insertEvent(
      HelmetEventRecord(
        id: incident.id,
        timestamp: incident.timestamp,
        eventType: HelmetEventType.accident,
        title: incident.title,
        description: incident.description,
        severity: EventSeverity.critical,
        isDemo: _isDemoMode,
        latitude: telemetry.latitude,
        longitude: telemetry.longitude,
        speedKmh: telemetry.speedKmh,
        gForce: telemetry.lastImpactForceG,
        status: 'detected',
        metadata: {'pitchAngle': telemetry.pitchAngle, 'rollAngle': telemetry.rollAngle},
      ),
    );

    // Notify user
    _notificationService.notify(
      title: 'CRITICAL ALERT: Impact Detected!',
      body: 'High-G collision registered (${telemetry.lastImpactForceG} G). Emergency SOS initiated.',
      severity: EventSeverity.critical,
      isDemo: _isDemoMode,
      actionRoute: '/emergency_warning',
    );

    _emergencyService.startCountdown(
      totalSeconds: _storageService.sosCountdownDuration,
      triggerIncident: incident,
      contacts: _storageService.emergencyContacts,
      onDispatched: (dispatchedReport) {},
    );
  }

  /// Manual SOS trigger from app or helmet button
  void triggerManualSos() {
    final incident = IncidentReport(
      id: 'SOS-MANUAL-${DateTime.now().millisecondsSinceEpoch}',
      type: IncidentType.sosManualTrigger,
      severity: IncidentSeverity.critical,
      title: 'Manual Emergency SOS Activated',
      description: 'Rider initiated manual distress broadcast.',
      latitude: _telemetryData.latitude,
      longitude: _telemetryData.longitude,
      speedKmh: _telemetryData.speedKmh,
      peakGForce: _telemetryData.lastImpactForceG,
      timestamp: DateTime.now(),
    );

    _activeEmergencyIncident = incident;

    // Log to SQLite
    _databaseService.insertEvent(
      HelmetEventRecord(
        id: incident.id,
        timestamp: incident.timestamp,
        eventType: HelmetEventType.sos,
        title: incident.title,
        description: incident.description,
        severity: EventSeverity.emergency,
        isDemo: _isDemoMode,
        latitude: _telemetryData.latitude,
        longitude: _telemetryData.longitude,
        speedKmh: _telemetryData.speedKmh,
        gForce: _telemetryData.lastImpactForceG,
        status: 'pending',
      ),
    );

    // Notify user
    _notificationService.notify(
      title: 'EMERGENCY SOS: Distress Broadcast',
      body: 'Manual SOS alert initiated. Transmitting coordinates to emergency contacts.',
      severity: EventSeverity.emergency,
      isDemo: _isDemoMode,
      actionRoute: '/emergency_warning',
    );

    _emergencyService.startCountdown(
      totalSeconds: _storageService.sosCountdownDuration,
      triggerIncident: incident,
      contacts: _storageService.emergencyContacts,
      onDispatched: (dispatched) {},
    );
    notifyListeners();
  }

  void _logHelmetStatusEvent({
    required String title,
    required String desc,
    required EventSeverity severity,
    required String status,
  }) {
    _databaseService.insertEvent(
      HelmetEventRecord(
        id: 'HLM-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        eventType: HelmetEventType.helmetStatus,
        title: title,
        description: desc,
        severity: severity,
        isDemo: _isDemoMode,
        status: status,
      ),
    );
  }

  void _logConnectionEvent({
    required String title,
    required String desc,
    required EventSeverity severity,
    required String status,
  }) {
    _databaseService.insertEvent(
      HelmetEventRecord(
        id: 'CONN-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        eventType: HelmetEventType.connection,
        title: title,
        description: desc,
        severity: severity,
        isDemo: _isDemoMode,
        status: status,
      ),
    );
  }

  void _logAlcoholEvent(double ppm) {
    _databaseService.insertEvent(
      HelmetEventRecord(
        id: 'ALC-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        eventType: HelmetEventType.alcoholLockout,
        title: 'Alcohol Interlock Prevention Triggered',
        description: 'MQ-3 sensor registered ${ppm.toStringAsFixed(1)} PPM (> 200 PPM limit). Ignition cut off immediately.',
        severity: EventSeverity.warning,
        isDemo: _isDemoMode,
        alcoholPpm: ppm,
        status: 'interlock_locked',
      ),
    );
  }

  void _logGpsFixAcquired(TelemetryData telemetry) {
    _databaseService.insertEvent(
      HelmetEventRecord(
        id: 'GPS-LOCK-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        eventType: HelmetEventType.gpsUpdate,
        title: 'GPS Satellite Fix Acquired',
        description: 'NEO-6M locked onto ${telemetry.gpsSatellites} satellites with precision telemetry.',
        severity: EventSeverity.info,
        isDemo: _isDemoMode,
        latitude: telemetry.latitude,
        longitude: telemetry.longitude,
        speedKmh: telemetry.speedKmh,
        status: 'locked',
      ),
    );
  }

  void _logGpsWaypoint(TelemetryData telemetry) {
    _databaseService.insertEvent(
      HelmetEventRecord(
        id: 'GPS-WAYPT-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        eventType: HelmetEventType.gpsUpdate,
        title: 'Trip Telemetry Waypoint',
        description: 'Cruising speed: ${telemetry.speedKmh.toInt()} km/h | Satellites: ${telemetry.gpsSatellites}',
        severity: EventSeverity.info,
        isDemo: _isDemoMode,
        latitude: telemetry.latitude,
        longitude: telemetry.longitude,
        speedKmh: telemetry.speedKmh,
        status: 'waypoint',
      ),
    );
  }

  // --- SQLite Query & Management Accessors ---

  Future<List<HelmetEventRecord>> getEvents({
    HelmetEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDemoOnly,
    String? searchQuery,
    int limit = 200,
    int offset = 0,
  }) async {
    return await _databaseService.getEvents(
      eventType: eventType,
      startDate: startDate,
      endDate: endDate,
      isDemoOnly: isDemoOnly,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, int>> getDatabaseStatistics() async {
    return await _databaseService.getStatistics();
  }

  Future<int> deleteEvent(String id) async {
    final deleted = await _databaseService.deleteEvent(id);
    notifyListeners();
    return deleted;
  }

  Future<int> clearEvents({bool demoOnly = false}) async {
    final cleared = await _databaseService.clearEvents(demoOnly: demoOnly);
    notifyListeners();
    return cleared;
  }

  /// Export filtered events into a formal PDF document
  Future<ReportExportResult> exportAuditReportPdf({
    List<HelmetEventRecord>? customEvents,
  }) async {
    final eventsToExport = customEvents ?? await _databaseService.getEvents(limit: 500);
    return await _reportExportService.generatePdfReport(
      events: eventsToExport,
      profile: userProfile,
      esp32Ip: esp32IpAddress,
    );
  }

  // --- In-App Notifications ---

  List<AppNotification> get notifications => _notificationService.notifications;
  int get unreadNotificationCount => _notificationService.unreadCount;
  Stream<AppNotification> get notificationStream => _notificationService.notificationStream;

  void markNotificationAsRead(String id) {
    _notificationService.markAsRead(id);
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    _notificationService.markAllAsRead();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notificationService.clearAll();
    notifyListeners();
  }

  void setTestEmergencyMode(bool isTest) {
    _emergencyService.setTestEmergencyMode(isTest);
    notifyListeners();
  }

  void acknowledgeActiveIncident({String acknowledgedBy = 'Rider Confirmed Safe'}) {
    _emergencyService.acknowledgeIncident(acknowledgedBy: acknowledgedBy);
    notifyListeners();
  }

  void cancelEmergencyCountdown() {
    _emergencyService.cancelCountdown();
    notifyListeners();
  }

  // --- Contacts & Profile Management ---

  void addEmergencyContact(EmergencyContact contact) {
    _storageService.addEmergencyContact(contact);
    notifyListeners();
  }

  void removeEmergencyContact(String id) {
    _storageService.removeEmergencyContact(id);
    notifyListeners();
  }

  void updateEmergencyContact(EmergencyContact contact) {
    _storageService.updateEmergencyContact(contact);
    notifyListeners();
  }

  void updateUserProfile(UserProfile profile) {
    _storageService.updateUserProfile(profile);
    notifyListeners();
  }

  void updateSettings({
    int? sosDuration,
    bool? soundAlerts,
    bool? simulationMode,
    bool? autoNightMode,
  }) {
    if (sosDuration != null) _storageService.sosCountdownDuration = sosDuration;
    if (soundAlerts != null) _storageService.soundAlertsEnabled = soundAlerts;
    if (simulationMode != null) {
      _storageService.simulationModeEnabled = simulationMode;
      if (simulationMode) {
        switchToDemoMode();
      }
    }
    if (autoNightMode != null) _storageService.autoNightModeEnabled = autoNightMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _helmetSub?.cancel();
    _sensorSub?.cancel();
    _telemetrySub?.cancel();
    _sosCountdownSub?.cancel();
    _emergencyDispatchedSub?.cancel();
    _emergencyStatusSub?.cancel();
    _mockService.dispose();
    _esp32RestService.dispose();
    _emergencyService.dispose();
    super.dispose();
  }
}
