import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_notification.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/notification_banner.dart';
import '../widgets/emergency/sos_countdown_dialog.dart';
import 'accident_monitoring_screen.dart';
import 'dashboard_screen.dart';
import 'emergency_warning_screen.dart';
import 'gps_tracking_screen.dart';
import 'history_reports_screen.dart';
import 'profile_screen.dart';

/// MainNavigationShell provides seamless navigation across the core hubs:
/// 1. Home
/// 2. Monitoring
/// 3. Location
/// 4. History
/// 5. Profile
class MainNavigationShell extends StatefulWidget {
  final AppStateProvider? stateProvider;
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.stateProvider,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late final AppStateProvider _stateProvider;
  late int _currentIndex;
  bool _isSosDialogShowing = false;
  AppNotification? _activeNotification;
  StreamSubscription<AppNotification>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _stateProvider = widget.stateProvider ?? AppStateProvider();
    _stateProvider.addListener(_onStateChanged);

    _notificationSub = _stateProvider.notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          _activeNotification = notification;
        });
      }
    });
  }

  void _onStateChanged() {
    if (_stateProvider.isSosCountdownActive && !_isSosDialogShowing && mounted) {
      _showAutonomousSosModal();
    }
  }

  void _showAutonomousSosModal() {
    _isSosDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _stateProvider,
          builder: (context, _) {
            if (!_stateProvider.isSosCountdownActive) {
              if (_isSosDialogShowing) {
                _isSosDialogShowing = false;
                Navigator.of(ctx).pop();
              }
            }
            return SosCountdownDialog(
              remainingSeconds: _stateProvider.sosRemainingSeconds,
              incident: _stateProvider.activeEmergencyIncident,
              onCancel: () {
                _stateProvider.cancelEmergencyCountdown();
                _isSosDialogShowing = false;
                Navigator.of(ctx).pop();
              },
              onDispatchNow: () {
                _stateProvider.cancelEmergencyCountdown();
                _isSosDialogShowing = false;
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EmergencyWarningScreen(stateProvider: _stateProvider)),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      _isSosDialogShowing = false;
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _stateProvider.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _stateProvider,
      builder: (context, _) {
        final screens = [
          DashboardScreen(stateProvider: _stateProvider),
          AccidentMonitoringScreen(stateProvider: _stateProvider),
          GpsTrackingScreen(stateProvider: _stateProvider),
          HistoryReportsScreen(stateProvider: _stateProvider),
          ProfileScreen(stateProvider: _stateProvider),
        ];

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          // IndexedStack preserves state across all tabs without rebuilding or losing state!
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
              if (_activeNotification != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: NotificationBanner(
                    notification: _activeNotification!,
                    onDismiss: () {
                      if (mounted) {
                        setState(() => _activeNotification = null);
                      }
                    },
                    onTap: () {
                      if (_activeNotification?.actionRoute == '/emergency_warning') {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => EmergencyWarningScreen(stateProvider: _stateProvider)),
                        );
                      } else {
                        // Switch to History tab
                        setState(() => _currentIndex = 3);
                      }
                    },
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColors.cyanAccent),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart, color: AppColors.cyanAccent),
                  label: 'Monitoring',
                ),
                NavigationDestination(
                  icon: Icon(Icons.location_on_outlined),
                  selectedIcon: Icon(Icons.location_on, color: AppColors.cyanAccent),
                  label: 'Location',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history, color: AppColors.cyanAccent),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.cyanAccent),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
