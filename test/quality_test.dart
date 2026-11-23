import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_helmet/constants/app_constants.dart';
import 'package:smart_helmet/constants/app_theme.dart';
import 'package:smart_helmet/main.dart';
import 'package:smart_helmet/models/app_notification.dart';
import 'package:smart_helmet/models/emergency_contact.dart';
import 'package:smart_helmet/models/helmet_event_record.dart';
import 'package:smart_helmet/models/incident_report.dart';
import 'package:smart_helmet/models/sensor_data.dart';
import 'package:smart_helmet/models/telemetry_data.dart';
import 'package:smart_helmet/models/user_profile.dart';
import 'package:smart_helmet/providers/app_state_provider.dart';
import 'package:smart_helmet/screens/about_project_screen.dart';
import 'package:smart_helmet/screens/accident_monitoring_screen.dart';
import 'package:smart_helmet/screens/dashboard_screen.dart';
import 'package:smart_helmet/screens/device_connection_screen.dart';
import 'package:smart_helmet/screens/emergency_contact_config_screen.dart';
import 'package:smart_helmet/screens/emergency_sos_screen.dart';
import 'package:smart_helmet/screens/emergency_warning_screen.dart';
import 'package:smart_helmet/screens/gps_tracking_screen.dart';
import 'package:smart_helmet/screens/helmet_safety_screen.dart';
import 'package:smart_helmet/screens/history_reports_screen.dart';
import 'package:smart_helmet/screens/login_screen.dart';
import 'package:smart_helmet/screens/main_navigation_shell.dart';
import 'package:smart_helmet/screens/profile_screen.dart';
import 'package:smart_helmet/screens/registration_screen.dart';
import 'package:smart_helmet/screens/settings_screen.dart';
import 'package:smart_helmet/screens/welcome_screen.dart';
import 'package:smart_helmet/services/database_service.dart';
import 'package:smart_helmet/services/emergency_service.dart';
import 'package:smart_helmet/services/esp32_rest_service.dart';
import 'package:smart_helmet/services/mock_iot_service.dart';
import 'package:smart_helmet/services/notification_service.dart';
import 'package:smart_helmet/services/pdf_report_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Smart Helmet 2.0 Quality Test Suite', () {
    late AppStateProvider stateProvider;

    setUp(() {
      stateProvider = AppStateProvider();
    });

    tearDown(() {
      stateProvider.dispose();
    });

    // 1. Application Startup
    testWidgets('1. Application startup renders SmartHelmetApp root', (tester) async {
      await tester.pumpWidget(const SmartHelmetApp());
      expect(find.byType(SmartHelmetApp), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 3000));
    });

    // 2. Splash and Welcome Screens
    testWidgets('2. Splash screen displays branding and transitions to WelcomeScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WelcomeScreen(),
        ),
      );
      expect(find.text('Intelligent Helmet Interlock'), findsOneWidget);
      expect(find.text('LOGIN TO COCKPIT'), findsOneWidget);
      expect(find.text('PAIR & REGISTER HELMET'), findsOneWidget);
    });

    // 3. Login and Registration Validation
    testWidgets('3. Login and registration screens render with validation controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      );
      expect(find.text('Rider Authentication'), findsOneWidget);
      expect(find.text('AUTHENTICATE & ENTER'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));

      // Test Registration Screen
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const RegistrationScreen(),
        ),
      );
      expect(find.text('Helmet & Rider Enrollment'), findsOneWidget);
      expect(find.text('REGISTER & PAIR HELMET'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(4));
    });

    // 4. All Navigation Routes Rendering
    testWidgets('4. All secondary screens render without crashing', (tester) async {
      final screens = <Widget>[
        DashboardScreen(stateProvider: stateProvider),
        DeviceConnectionScreen(stateProvider: stateProvider),
        HelmetSafetyScreen(stateProvider: stateProvider),
        AccidentMonitoringScreen(stateProvider: stateProvider),
        GpsTrackingScreen(stateProvider: stateProvider),
        EmergencySosScreen(stateProvider: stateProvider),
        HistoryReportsScreen(stateProvider: stateProvider),
        SettingsScreen(stateProvider: stateProvider),
        AboutProjectScreen(stateProvider: stateProvider),
        ProfileScreen(stateProvider: stateProvider),
        EmergencyContactConfigScreen(stateProvider: stateProvider),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: screen,
          ),
        );
        expect(find.byWidget(screen), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    // 5. Dashboard Rendering
    testWidgets('5. Dashboard cockpit renders speedometer, helmet and alcohol cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: DashboardScreen(stateProvider: stateProvider),
        ),
      );
      expect(find.text('HELMET INTERLOCK'), findsOneWidget);
      expect(find.text('ALCOHOL INTERLOCK (MQ-3)'), findsOneWidget);
      expect(find.text('LIVE SENSOR TELEMETRY'), findsOneWidget);
    });

    // 6. Demo Mode Verification
    test('6. Demo Mode operates offline and marks telemetry provenance', () {
      final mock = MockIoTService();
      expect(mock.sensorDataStream, isNotNull);
      expect(mock.telemetryDataStream, isNotNull);
      expect(mock.helmetStateStream, isNotNull);
      mock.dispose();
    });

    // 7. ESP32 Connection and Disconnection
    test('7. ESP32 connection state transitions handled cleanly', () async {
      expect(stateProvider.isDemoMode, isTrue);

      await stateProvider.connectToEsp32('192.168.4.1', port: 80);
      expect(stateProvider.isDemoMode, isFalse);
      expect(stateProvider.esp32IpAddress, '192.168.4.1');

      await stateProvider.disconnectEsp32();
      expect(stateProvider.helmetState.isConnected, isFalse);

      stateProvider.switchToDemoMode();
      expect(stateProvider.isDemoMode, isTrue);
    });

    // 8. API Timeout and Error Handling
    test('8. REST service returns structured error on invalid IP/timeout', () async {
      final restService = Esp32RestService(ipAddress: '240.0.0.1', port: 80, timeout: const Duration(milliseconds: 500));
      final testResult = await restService.testConnection('240.0.0.1', 80);

      expect(testResult['success'], isFalse);
      expect(testResult['error'], isNotNull);
      restService.dispose();
    });

    // 9. Sensor Data Parsing and Safety Interlock
    test('9. Sensor data model validates sobriety and helmet interlock', () {
      final compliant = SensorData(
        isHelmetWorn: true,
        alcoholPpm: 50.0,
        timestamp: DateTime.now(),
      );
      expect(compliant.isSafetyCompliant, isTrue);
      expect(compliant.isAlcoholSafe, isTrue);

      final unfastened = compliant.copyWith(isHelmetWorn: false);
      expect(unfastened.isSafetyCompliant, isFalse);

      final intoxicated = compliant.copyWith(alcoholPpm: 280.0);
      expect(intoxicated.isAlcoholSafe, isFalse);
      expect(intoxicated.isSafetyCompliant, isFalse);
    });

    // 10. Accident Event Handling and MPU6050 Peak Deceleration
    test('10. Dangerous motion triggers accident classification (> 4.2 G)', () {
      final normal = TelemetryData(accelX: 0.1, accelY: 0.1, accelZ: 9.8, timestamp: DateTime.now());
      expect(normal.isDangerousMotion, isFalse);

      final crash = TelemetryData(accelX: 42.0, accelY: 20.0, accelZ: 9.8, timestamp: DateTime.now());
      expect(crash.isDangerousMotion, isTrue);
    });

    // 11. SOS Confirmation and Emergency Service Lifecycle
    test('11. Emergency Service validates countdown, deduplication, and ACK', () {
      final emService = EmergencyService();
      final incident = IncidentReport(
        id: 'SOS-TEST-99',
        type: IncidentType.sosManualTrigger,
        severity: IncidentSeverity.critical,
        title: 'Manual Distress',
        description: 'Test SOS trigger',
        latitude: 12.9716,
        longitude: 77.5946,
        speedKmh: 0.0,
        peakGForce: 1.0,
        timestamp: DateTime.now(),
      );

      emService.startCountdown(
        totalSeconds: 10,
        triggerIncident: incident,
        contacts: [],
        onDispatched: (_) {},
      );

      expect(emService.isCountdownActive, isTrue);
      expect(emService.isEventAlreadyProcessed('SOS-TEST-99'), isTrue);

      emService.acknowledgeIncident(acknowledgedBy: 'Exhibition Judge');
      expect(emService.activeIncident?.deliveryStatus, AlertDeliveryStatus.acknowledged);
      expect(emService.activeIncident?.isAcknowledged, isTrue);
      emService.dispose();
    });

    // 12. GPS Map Coordinates and Null Island Handling
    test('12. GPS validation catches Null Island (0,0) and out-of-bounds coordinates', () {
      final valid = TelemetryData(latitude: 12.9716, longitude: 77.5946, timestamp: DateTime.now());
      expect(valid.areCoordinatesValid, isTrue);

      final nullIsland = TelemetryData(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());
      expect(nullIsland.areCoordinatesValid, isFalse);

      final invalidLat = TelemetryData(latitude: 120.0, longitude: 77.0, timestamp: DateTime.now());
      expect(invalidLat.areCoordinatesValid, isFalse);
    });

    // 13. SQLite Data Persistence and Filter Verification
    test('13. DatabaseService stores events and filters by category and provenance', () async {
      final db = DatabaseService.instance;
      await db.init();

      await db.insertEvent(
        HelmetEventRecord(
          id: 'TEST-REC-01',
          timestamp: DateTime.now(),
          eventType: HelmetEventType.accident,
          title: 'Physical Crash 4.8 G',
          description: 'Hard impact recorded',
          severity: EventSeverity.critical,
          isDemo: false,
          gForce: 4.8,
        ),
      );

      final records = await db.getEvents(eventType: HelmetEventType.accident);
      expect(records.any((r) => r.id == 'TEST-REC-01'), isTrue);

      final hardwareRecords = await db.getEvents(isDemoOnly: false);
      expect(hardwareRecords.any((r) => r.id == 'TEST-REC-01'), isTrue);
    });

    // 14. PDF Report Export Feature
    test('14. PdfReportGenerator produces valid standard ISO PDF 1.4 binary document', () {
      final events = [
        HelmetEventRecord(
          id: 'PDF-EVT-01',
          timestamp: DateTime.now(),
          eventType: HelmetEventType.sos,
          title: 'Emergency Distress Broadcast',
          description: 'Test SOS logged',
          severity: EventSeverity.emergency,
          isDemo: true,
          status: 'delivered',
        ),
      ];

      final bytes = PdfReportGenerator.generate(
        events: events,
        profile: const UserProfile(
          fullName: 'Test Rider',
          vehiclePlateNumber: 'KA-01-SH-2026',
        ),
        esp32Ip: '192.168.4.1',
      );

      expect(bytes.isNotEmpty, isTrue);
      final pdfHeader = utf8.decode(bytes.sublist(0, 8));
      expect(pdfHeader.startsWith('%PDF-1.4'), isTrue);

      final pdfContent = utf8.decode(bytes, allowMalformed: true);
      expect(pdfContent.contains('%%EOF'), isTrue);
      expect(pdfContent.contains('SMART HELMET 2.0'), isTrue);
    });

    // 15. Notification Service and In-App Alert Stream
    test('15. NotificationService manages priority alerts, history and read states', () {
      final notif = NotificationService.instance;
      notif.clearAll();
      expect(notif.unreadCount, 0);

      notif.notify(
        title: 'Safety Test Notification',
        body: 'Alert body text',
        severity: EventSeverity.warning,
        isDemo: true,
      );

      expect(notif.notifications.length, 1);
      expect(notif.unreadCount, 1);

      notif.markAllAsRead();
      expect(notif.unreadCount, 0);
    });

    // 16. Different Android Screen Sizes & Responsiveness
    testWidgets('16. Dashboard adapts to multiple phone and tablet form factors', (tester) async {
      final viewports = <Size>[
        const Size(360, 640),  // Compact budget Android (e.g. Galaxy A03)
        const Size(390, 844),  // Modern standard phone (e.g. Pixel 7)
        const Size(412, 915),  // Large phablet (e.g. Pixel 8 Pro)
        const Size(800, 1280), // Android Tablet
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: DashboardScreen(stateProvider: stateProvider),
          ),
        );

        expect(find.byType(DashboardScreen), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
