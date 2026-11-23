import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/helmet_event_record.dart';

/// Abstract storage contract for SQLite and persistent event backends.
abstract class DatabaseStorageAdapter {
  Future<bool> init();
  Future<int> insert(HelmetEventRecord event);
  Future<List<HelmetEventRecord>> query({
    HelmetEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDemoOnly,
    String? searchQuery,
    int limit = 200,
    int offset = 0,
  });
  Future<int> count();
  Future<int> delete(String id);
  Future<int> clear({bool demoOnly = false});
  Future<void> close();
}

/// Fallback storage engine with persistent file/memory capability for test environments and web.
class FallbackStorageAdapter implements DatabaseStorageAdapter {
  final List<HelmetEventRecord> _records = [];
  File? _persistenceFile;

  FallbackStorageAdapter() {
    try {
      final tempDir = Directory.systemTemp;
      _persistenceFile = File('${tempDir.path}/smart_helmet_events_fallback.json');
    } catch (_) {
      _persistenceFile = null;
    }
  }

  @override
  Future<bool> init() async {
    if (_persistenceFile != null && _persistenceFile!.existsSync()) {
      try {
        final content = await _persistenceFile!.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _records.clear();
        for (final item in list) {
          _records.add(HelmetEventRecord.fromMap(Map<String, dynamic>.from(item)));
        }
      } catch (_) {}
    }
    return true;
  }

  Future<void> _saveToDisk() async {
    if (_persistenceFile != null) {
      try {
        final jsonStr = jsonEncode(_records.map((r) => r.toMap()).toList());
        await _persistenceFile!.writeAsString(jsonStr, flush: true);
      } catch (_) {}
    }
  }

  @override
  Future<int> insert(HelmetEventRecord event) async {
    _records.removeWhere((e) => e.id == event.id);
    _records.insert(0, event);
    await _saveToDisk();
    return 1;
  }

  @override
  Future<List<HelmetEventRecord>> query({
    HelmetEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDemoOnly,
    String? searchQuery,
    int limit = 200,
    int offset = 0,
  }) async {
    var filtered = List<HelmetEventRecord>.from(_records);

    if (eventType != null) {
      filtered = filtered.where((e) => e.eventType == eventType).toList();
    }
    if (startDate != null) {
      filtered = filtered.where((e) => !e.timestamp.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((e) => !e.timestamp.isAfter(endDate)).toList();
    }
    if (isDemoOnly != null) {
      filtered = filtered.where((e) => e.isDemo == isDemoOnly).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.description.toLowerCase().contains(q) ||
        (e.status != null && e.status!.toLowerCase().contains(q))
      ).toList();
    }

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final start = offset.clamp(0, filtered.length);
    final end = (start + limit).clamp(start, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Future<int> count() async => _records.length;

  @override
  Future<int> delete(String id) async {
    final before = _records.length;
    _records.removeWhere((e) => e.id == id);
    await _saveToDisk();
    return before - _records.length;
  }

  @override
  Future<int> clear({bool demoOnly = false}) async {
    final before = _records.length;
    if (demoOnly) {
      _records.removeWhere((e) => e.isDemo);
    } else {
      _records.clear();
    }
    await _saveToDisk();
    return before - _records.length;
  }

  @override
  Future<void> close() async {}
}

/// Central database service managing persistent storage of safety and IoT telemetry events.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  DatabaseStorageAdapter _adapter = FallbackStorageAdapter();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Set the active storage adapter (e.g. SqfliteStorageAdapter for Android)
  void setAdapter(DatabaseStorageAdapter adapter) {
    _adapter = adapter;
    _isInitialized = false;
  }

  /// Initialize database connection and schema
  Future<void> init({DatabaseStorageAdapter? customAdapter}) async {
    if (customAdapter != null) {
      _adapter = customAdapter;
    }

    final success = await _adapter.init();
    if (!success && _adapter is! FallbackStorageAdapter) {
      print('[DatabaseService] Adapter ${_adapter.runtimeType} init failed. Falling back to FallbackStorageAdapter.');
      _adapter = FallbackStorageAdapter();
      await _adapter.init();
    }
    _isInitialized = true;

    final count = await _adapter.count();
    if (count == 0) {
      await seedInitialExhibitionData();
    }
    print('[DatabaseService] Initialized adapter (${_adapter.runtimeType}), records: $count');
  }

  /// Insert a single safety or IoT event into SQLite
  Future<int> insertEvent(HelmetEventRecord event) async {
    if (!_isInitialized) await init();
    return await _adapter.insert(event);
  }

  /// Query events with comprehensive filtering
  Future<List<HelmetEventRecord>> getEvents({
    HelmetEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDemoOnly,
    String? searchQuery,
    int limit = 200,
    int offset = 0,
  }) async {
    if (!_isInitialized) await init();
    return await _adapter.query(
      eventType: eventType,
      startDate: startDate,
      endDate: endDate,
      isDemoOnly: isDemoOnly,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }

  /// Get total count of records
  Future<int> getEventCount() async {
    if (!_isInitialized) await init();
    return await _adapter.count();
  }

  /// Delete a single event
  Future<int> deleteEvent(String id) async {
    if (!_isInitialized) await init();
    return await _adapter.delete(id);
  }

  /// Clear all events or demo events only
  Future<int> clearEvents({bool demoOnly = false}) async {
    if (!_isInitialized) await init();
    return await _adapter.clear(demoOnly: demoOnly);
  }

  /// Retrieve summary statistics for reports and dashboard audit cards
  Future<Map<String, int>> getStatistics() async {
    final allEvents = await getEvents(limit: 500);

    int total = allEvents.length;
    int demoCount = allEvents.where((e) => e.isDemo).length;
    int hardwareCount = total - demoCount;
    int accidentCount = allEvents.where((e) => e.eventType == HelmetEventType.accident).length;
    int sosCount = allEvents.where((e) => e.eventType == HelmetEventType.sos).length;
    int alcoholLockoutCount = allEvents.where((e) => e.eventType == HelmetEventType.alcoholLockout).length;
    int helmetChangeCount = allEvents.where((e) => e.eventType == HelmetEventType.helmetStatus).length;
    int connectionCount = allEvents.where((e) => e.eventType == HelmetEventType.connection).length;
    int gpsCount = allEvents.where((e) => e.eventType == HelmetEventType.gpsUpdate).length;

    return {
      'total': total,
      'hardware': hardwareCount,
      'demo': demoCount,
      'accidents': accidentCount,
      'sos': sosCount,
      'alcoholLockouts': alcoholLockoutCount,
      'helmetChanges': helmetChangeCount,
      'connections': connectionCount,
      'gpsUpdates': gpsCount,
    };
  }

  /// Seed initial exhibition events so the app starts with realistic telemetry history
  Future<void> seedInitialExhibitionData() async {
    final now = DateTime.now();

    final seedRecords = [
      HelmetEventRecord(
        id: 'EVT-INIT-001',
        timestamp: now.subtract(const Duration(minutes: 5)),
        eventType: HelmetEventType.connection,
        title: 'ESP32 Wi-Fi Gateway Connected',
        description: 'IoT telemetry channel established on 192.168.4.1:80. Sensor heartbeat normal.',
        severity: EventSeverity.info,
        isDemo: true,
        status: 'connected',
        metadata: {'ip': '192.168.4.1', 'protocol': 'HTTP/1.1 REST', 'rssi': -58},
      ),
      HelmetEventRecord(
        id: 'EVT-INIT-002',
        timestamp: now.subtract(const Duration(minutes: 4)),
        eventType: HelmetEventType.helmetStatus,
        title: 'Safety Helmet Fastened & Worn',
        description: 'IR optical proximity sensor triggered. 12V Ignition relay circuit energized.',
        severity: EventSeverity.info,
        isDemo: true,
        status: 'interlock_unlocked',
        metadata: {'ir_reading': 1, 'relay_pin': 14},
      ),
      HelmetEventRecord(
        id: 'EVT-INIT-003',
        timestamp: now.subtract(const Duration(minutes: 3)),
        eventType: HelmetEventType.gpsUpdate,
        title: 'GPS Satellite Fix Acquired',
        description: 'NEO-6M locked onto 8 satellites with 1.8m horizontal precision.',
        severity: EventSeverity.info,
        isDemo: true,
        latitude: 12.9716,
        longitude: 77.5946,
        speedKmh: 0.0,
        status: 'locked',
        metadata: {'satellites': 8, 'hdop': 1.1},
      ),
      HelmetEventRecord(
        id: 'EVT-INIT-004',
        timestamp: now.subtract(const Duration(minutes: 2)),
        eventType: HelmetEventType.alcoholLockout,
        title: 'Alcohol Interlock Prevention Triggered',
        description: 'MQ-3 sensor registered 245 PPM (> 200 PPM limit). Ignition cut off immediately.',
        severity: EventSeverity.warning,
        isDemo: true,
        alcoholPpm: 245.0,
        status: 'interlock_locked',
        metadata: {'threshold_ppm': 200.0, 'raw_adc': 2890},
      ),
      HelmetEventRecord(
        id: 'EVT-INIT-005',
        timestamp: now.subtract(const Duration(minutes: 1)),
        eventType: HelmetEventType.accident,
        title: 'Simulation: Sudden Impact Detected',
        description: 'MPU6050 recorded 4.2 G peak deceleration and 68° tilt. SOS countdown initiated.',
        severity: EventSeverity.critical,
        isDemo: true,
        latitude: 12.9716,
        longitude: 77.5946,
        speedKmh: 42.0,
        gForce: 4.2,
        status: 'delivered',
        metadata: {
          'gsm_ack': '+CMGS: 104',
          'recipients': 'Dr. Alok Verma, City Ambulance',
          'sos_triggered': true,
        },
      ),
    ];

    for (final record in seedRecords) {
      await _adapter.insert(record);
    }
  }

  Future<void> close() async {
    await _adapter.close();
    _isInitialized = false;
  }
}
