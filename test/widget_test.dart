import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_helmet/constants/app_constants.dart';
import 'package:smart_helmet/constants/app_theme.dart';
import 'package:smart_helmet/main.dart';
import 'package:smart_helmet/providers/app_state_provider.dart';
import 'package:smart_helmet/screens/main_navigation_shell.dart';

void main() {
  testWidgets('Smart Helmet 2.0 launches with splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHelmetApp());

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.projectTagline), findsOneWidget);

    // Pump frame to avoid pending timers
    await tester.pump(const Duration(milliseconds: 3000));
  });

  testWidgets('MainNavigationShell renders all 5 bottom navigation tabs and allows switching', (WidgetTester tester) async {
    final stateProvider = AppStateProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationShell(stateProvider: stateProvider),
      ),
    );

    // Verify all 5 destinations are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Monitoring'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Switch to Monitoring Tab
    await tester.tap(find.text('Monitoring'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sensor & Crash Monitoring'), findsOneWidget);

    // Switch to Location Tab
    await tester.tap(find.text('Location'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('GPS Tracking Telemetry'), findsOneWidget);

    // Switch to History Tab
    await tester.tap(find.text('History'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Safety History & Reports'), findsOneWidget);

    // Switch to Profile Tab
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Rider & System Profile'), findsOneWidget);

    stateProvider.dispose();
  });

  test('AppStateProvider toggles between Demo Mode and physical ESP32 mode', () async {
    final stateProvider = AppStateProvider();
    expect(stateProvider.isDemoMode, isTrue);

    await stateProvider.connectToEsp32('192.168.4.1', port: 80);
    expect(stateProvider.isDemoMode, isFalse);
    expect(stateProvider.esp32IpAddress, '192.168.4.1');
    expect(stateProvider.esp32Port, 80);

    stateProvider.switchToDemoMode();
    expect(stateProvider.isDemoMode, isTrue);
    stateProvider.dispose();
  });
}
