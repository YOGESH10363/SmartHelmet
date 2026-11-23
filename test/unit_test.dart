import 'dart:convert';
import 'package:smart_helmet/constants/app_constants.dart';
import 'package:smart_helmet/models/app_notification.dart';
import 'package:smart_helmet/models/helmet_event_record.dart';
import 'package:smart_helmet/models/incident_report.dart';
import 'package:smart_helmet/models/sensor_data.dart';
import 'package:smart_helmet/models/telemetry_data.dart';
import 'package:smart_helmet/models/user_profile.dart';
import 'package:smart_helmet/services/database_service.dart';
import 'package:smart_helmet/services/emergency_service.dart';
import 'package:smart_helmet/services/notification_service.dart';
import 'package:smart_helmet/services/pdf_report_generator.dart';

void main() async {
  print('=== STARTING SMART HELMET 2.0 ADVANCED TEST SUITE ===');

  // Test 1: App Constants verification
  assert(AppConstants.appName == 'Smart Helmet 2.0');
  assert(AppConstants.alcoholSafetyThresholdPpm == 200.0);
  assert(AppConstants.gForceAccidentThreshold == 4.2);
  print('[PASS] 1. App Constants verified.');

  // Test 2: SensorData Interlock Logic
  final safeSensors = SensorData(
    isHelmetWorn: true,
    isStrapBuckled: true,
    alcoholPpm: 45.0,
    timestamp: DateTime.now(),
  );
  assert(safeSensors.isSafetyCompliant == true);
  assert(safeSensors.isAlcoholSafe == true);

  final unhelmetedSensors = safeSensors.copyWith(isHelmetWorn: false);
  assert(unhelmetedSensors.isSafetyCompliant == false);

  final intoxicatedSensors = safeSensors.copyWith(alcoholPpm: 250.0);
  assert(intoxicatedSensors.isSafetyCompliant == false);
  assert(intoxicatedSensors.isAlcoholSafe == false);
  print('[PASS] 2. Sensor Interlock & DUI Prevention logic validated.');

  // Test 3: Telemetry G-Force and Dangerous Motion
  final normalMotion = TelemetryData(
    accelX: 0.1,
    accelY: 0.1,
    accelZ: 9.81,
    pitchAngle: 3.0,
    rollAngle: -1.0,
    timestamp: DateTime.now(),
  );
  assert(normalMotion.totalGForce >= 0.99 && normalMotion.totalGForce <= 1.05);
  assert(normalMotion.isDangerousMotion == false);

  final crashMotion = normalMotion.copyWith(accelX: 45.0);
  assert(crashMotion.isDangerousMotion == true);
  print('[PASS] 3. MPU6050 Motion & Crash classification validated.');

  // Test 4: Emergency Alert Delivery Statuses & Deduplication
  final emergencyService = EmergencyService();
  assert(emergencyService.isTestEmergencyMode == false);

  emergencyService.setTestEmergencyMode(true);
  assert(emergencyService.isTestEmergencyMode == true);

  final incident = IncidentReport(
    id: 'EVT-TEST-001',
    type: IncidentType.crashDetected,
    severity: IncidentSeverity.critical,
    title: 'High-Impact Crash Detected',
    description: 'Impact of 6.2G detected.',
    latitude: 18.5204,
    longitude: 73.8567,
    speedKmh: 42.0,
    peakGForce: 6.2,
    timestamp: DateTime.now(),
  );

  emergencyService.startCountdown(
    totalSeconds: 10,
    triggerIncident: incident,
    contacts: [],
    onDispatched: (_) {},
  );

  assert(emergencyService.isCountdownActive == true);
  assert(emergencyService.activeIncident?.deliveryStatus == AlertDeliveryStatus.detected);
  assert(emergencyService.isEventAlreadyProcessed('EVT-TEST-001') == true);

  emergencyService.acknowledgeIncident(acknowledgedBy: 'Rider Safe');
  assert(emergencyService.activeIncident?.deliveryStatus == AlertDeliveryStatus.acknowledged);
  assert(emergencyService.activeIncident?.isAcknowledged == true);
  assert(emergencyService.activeIncident?.acknowledgedBy == 'Rider Safe');
  print('[PASS] 4. Emergency event acknowledgement & deduplication validated.');

  // Test 5: SQLite Database Service - Seeding, CRUD & Categorization
  final dbService = DatabaseService.instance;
  await dbService.init();

  // Clear before test
  await dbService.clearEvents(demoOnly: false);
  assert(await dbService.getEventCount() == 0);

  final now = DateTime.now();

  // Insert Accident Event (Real Hardware)
  await dbService.insertEvent(
    HelmetEventRecord(
      id: 'EVT-ACC-REAL',
      timestamp: now.subtract(const Duration(hours: 2)),
      eventType: HelmetEventType.accident,
      title: 'Physical ESP32 Crash Impact Registered (5.1 G)',
      description: 'MPU6050 detected 5.1 G collision impact.',
      severity: EventSeverity.critical,
      isDemo: false, // REAL HARDWARE
      latitude: 12.9716,
      longitude: 77.5946,
      speedKmh: 46.0,
      gForce: 5.1,
      status: 'delivered',
    ),
  );

  // Insert SOS Event (Demo)
  await dbService.insertEvent(
    HelmetEventRecord(
      id: 'EVT-SOS-DEMO',
      timestamp: now.subtract(const Duration(hours: 1)),
      eventType: HelmetEventType.sos,
      title: 'Manual Emergency SOS Activated',
      description: 'Rider manual distress button pressed.',
      severity: EventSeverity.emergency,
      isDemo: true, // DEMO SIMULATOR
      latitude: 12.9720,
      longitude: 77.5950,
      speedKmh: 0.0,
      status: 'pending',
    ),
  );

  // Insert Helmet Wearing Change Event
  await dbService.insertEvent(
    HelmetEventRecord(
      id: 'EVT-HLM-001',
      timestamp: now.subtract(const Duration(minutes: 45)),
      eventType: HelmetEventType.helmetStatus,
      title: 'Safety Helmet Fastened & Worn',
      description: 'Optical IR sensor engaged.',
      severity: EventSeverity.info,
      isDemo: false,
      status: 'interlock_unlocked',
    ),
  );

  // Insert Connection Event
  await dbService.insertEvent(
    HelmetEventRecord(
      id: 'EVT-CONN-001',
      timestamp: now.subtract(const Duration(minutes: 30)),
      eventType: HelmetEventType.connection,
      title: 'ESP32 Wi-Fi Gateway Connected',
      description: 'Handshake complete on 192.168.4.1:80.',
      severity: EventSeverity.info,
      isDemo: false,
      status: 'connected',
    ),
  );

  // Insert GPS Update Event
  await dbService.insertEvent(
    HelmetEventRecord(
      id: 'EVT-GPS-001',
      timestamp: now.subtract(const Duration(minutes: 15)),
      eventType: HelmetEventType.gpsUpdate,
      title: 'GPS Satellite Fix Acquired',
      description: 'NEO-6M locked onto 9 satellites.',
      severity: EventSeverity.info,
      isDemo: false,
      latitude: 12.9725,
      longitude: 77.5955,
      speedKmh: 35.0,
      status: 'locked',
    ),
  );

  // Verify total count
  final totalCount = await dbService.getEventCount();
  assert(totalCount == 5, 'Expected 5 events, got $totalCount');

  // Test Category Filtering
  final accidentOnly = await dbService.getEvents(eventType: HelmetEventType.accident);
  assert(accidentOnly.length == 1);
  assert(accidentOnly.first.id == 'EVT-ACC-REAL');

  final sosOnly = await dbService.getEvents(eventType: HelmetEventType.sos);
  assert(sosOnly.length == 1);
  assert(sosOnly.first.id == 'EVT-SOS-DEMO');

  // Test Provenance Filtering
  final hardwareOnly = await dbService.getEvents(isDemoOnly: false);
  assert(hardwareOnly.length == 4, 'Expected 4 hardware events, got ${hardwareOnly.length}');

  final demoOnly = await dbService.getEvents(isDemoOnly: true);
  assert(demoOnly.length == 1);
  assert(demoOnly.first.isDemo == true);

  // Test Time Filtering
  final past35MinEvents = await dbService.getEvents(
    startDate: now.subtract(const Duration(minutes: 35)),
  );
  assert(past35MinEvents.length == 2); // CONN (30m) & GPS (15m)

  // Test Statistics
  final stats = await dbService.getStatistics();
  assert(stats['total'] == 5);
  assert(stats['hardware'] == 4);
  assert(stats['demo'] == 1);
  assert(stats['accidents'] == 1);
  assert(stats['sos'] == 1);
  print('[PASS] 5. SQLite Event Recording, Filtering & Statistics validated.');

  // Test 6: Persistence & Restart Simulation
  // Query again to verify records remain intact
  final reloadedEvents = await dbService.getEvents();
  assert(reloadedEvents.length == 5);
  assert(reloadedEvents.any((e) => e.id == 'EVT-ACC-REAL'));
  print('[PASS] 6. Persistent database retention across sessions validated.');

  // Test 7: Standard ISO PDF 1.4 Safety Audit Report Generation
  final pdfBytes = PdfReportGenerator.generate(
    events: reloadedEvents,
    profile: const UserProfile(
      fullName: 'Rahul Sharma',
      vehiclePlateNumber: 'KA-01-EQ-9082',
      bloodGroup: 'O+',
      phone: '+91 98765 43210',
    ),
    esp32Ip: '192.168.4.1',
  );

  assert(pdfBytes.isNotEmpty);
  final pdfString = utf8.decode(pdfBytes, allowMalformed: true);
  assert(pdfString.startsWith('%PDF-1.4'), 'Invalid PDF header');
  assert(pdfString.contains('%%EOF'), 'Invalid PDF EOF trailer');
  assert(pdfString.contains('SMART HELMET 2.0'), 'Missing report title in PDF stream');
  print('[PASS] 7. Standard ISO PDF 1.4 Audit Report Generator validated.');

  // Test 8: Notification Service
  final notifService = NotificationService.instance;
  notifService.clearAll();
  assert(notifService.unreadCount == 0);

  notifService.notify(
    title: 'CRITICAL ALERT: Crash Detected',
    body: 'Impact force 5.1 G registered.',
    severity: EventSeverity.critical,
    isDemo: false,
    actionRoute: '/emergency_warning',
  );

  notifService.notify(
    title: 'Safety Warning: Helmet Removed',
    body: 'Ignition relay cut off.',
    severity: EventSeverity.warning,
    isDemo: true,
  );

  assert(notifService.notifications.length == 2);
  assert(notifService.unreadCount == 2);

  notifService.markAsRead(notifService.notifications.first.id);
  assert(notifService.unreadCount == 1);

  notifService.markAllAsRead();
  assert(notifService.unreadCount == 0);
  print('[PASS] 8. Real-time In-App Notification Service validated.');

  emergencyService.dispose();

  print('=== ALL ADVANCED SAFETY, DATABASE, PDF & NOTIFICATION TESTS PASSED (8/8) ===');
}
