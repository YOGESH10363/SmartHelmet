import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/simulated_tag.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/dashboard/alcohol_status_card.dart';
import '../widgets/dashboard/helmet_status_card.dart';
import '../widgets/dashboard/speedometer_gauge.dart';
import '../widgets/emergency/sos_countdown_dialog.dart';
import 'accident_monitoring_screen.dart';
import 'device_connection_screen.dart';
import 'emergency_sos_screen.dart';
import 'emergency_warning_screen.dart';
import 'gps_tracking_screen.dart';

/// Screen 5: Home Dashboard (Cockpit / Telemetry HUD).
class DashboardScreen extends StatelessWidget {
  final AppStateProvider stateProvider;

  const DashboardScreen({super.key, required this.stateProvider});

  void _showSosModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: stateProvider,
          builder: (context, _) {
            if (!stateProvider.isSosCountdownActive) {
              Navigator.of(ctx).pop();
            }
            return SosCountdownDialog(
              remainingSeconds: stateProvider.sosRemainingSeconds,
              incident: stateProvider.activeEmergencyIncident,
              onCancel: () {
                stateProvider.cancelEmergencyCountdown();
                Navigator.of(ctx).pop();
              },
              onDispatchNow: () {
                stateProvider.cancelEmergencyCountdown();
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EmergencyWarningScreen(stateProvider: stateProvider)),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final helmet = stateProvider.helmetState;
    final sensor = stateProvider.sensorData;
    final telemetry = stateProvider.telemetryData;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Smart Helmet 2.0',
        subtitle: 'Cockpit Telemetry System',
        showBackButton: false,
        helmetState: helmet,
        onSosPressed: () {
          stateProvider.triggerManualSos();
          _showSosModal(context);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IoT Status & Simulation Tag Banner
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DeviceConnectionScreen(stateProvider: stateProvider)),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: helmet.isConnected ? 'ESP32 CONNECTED' : 'DISCONNECTED',
                          type: helmet.isConnected ? BadgeType.safe : BadgeType.offline,
                          icon: Icons.bluetooth,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${helmet.signalStrengthRssi} dBm',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  const SimulatedTag(),
                ],
              ),

              const SizedBox(height: 16),

              // Cockpit Hero: Animated Speedometer Gauge
              GlowContainer(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    SpeedometerGauge(
                      currentSpeed: telemetry.speedKmh,
                      maxSpeed: 120.0,
                    ),
                    const SizedBox(height: 14),
                    // Quick ride metrics strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickMetricItem(
                          label: 'TRIP DISTANCE',
                          value: '${telemetry.tripDistanceKm.toStringAsFixed(1)} KM',
                          icon: Icons.route,
                        ),
                        Container(width: 1, height: 28, color: AppColors.borderSubtle),
                        _QuickMetricItem(
                          label: 'RIDE DURATION',
                          value: '${(telemetry.tripDurationSeconds ~/ 60)} MIN',
                          icon: Icons.timer_outlined,
                        ),
                        Container(width: 1, height: 28, color: AppColors.borderSubtle),
                        _QuickMetricItem(
                          label: 'TOP SPEED',
                          value: '${telemetry.maxSpeedKmh.toStringAsFixed(0)} KM/H',
                          icon: Icons.bolt,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Safety Interlock 1: Helmet IR Sensor & Engine Relay
              HelmetStatusCard(
                sensorData: sensor,
                onToggleHelmet: (worn) => stateProvider.toggleHelmetWorn(worn),
              ),

              const SizedBox(height: 14),

              // Safety Interlock 2: MQ-3 Alcohol Breathalyzer
              AlcoholStatusCard(
                sensorData: sensor,
                onPpmChanged: (ppm) => stateProvider.setAlcoholPpm(ppm),
              ),

              const SizedBox(height: 16),

              // Telemetry Grid
              const Text(
                'LIVE SENSOR TELEMETRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cyanAccent,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'IMPACT FORCE',
                      value: telemetry.totalGForce.toStringAsFixed(2),
                      unit: 'G',
                      icon: Icons.vibration,
                      accentColor: telemetry.isDangerousMotion ? AppColors.statusEmergency : AppColors.cyanAccent,
                      subtitle: 'MPU6050 Accelerometer',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AccidentMonitoringScreen(stateProvider: stateProvider)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'HELMET TILT',
                      value: '${telemetry.pitchAngle.abs().toStringAsFixed(1)}°',
                      unit: 'DEG',
                      icon: Icons.screen_rotation_alt,
                      accentColor: AppColors.blueLight,
                      subtitle: 'Lean / Fall Pitch Angle',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AccidentMonitoringScreen(stateProvider: stateProvider)),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'GPS POSITION',
                      value: '${telemetry.gpsSatellites}',
                      unit: 'SATS',
                      icon: Icons.gps_fixed,
                      accentColor: AppColors.statusSafe,
                      subtitle: '${telemetry.latitude.toStringAsFixed(3)}, ${telemetry.longitude.toStringAsFixed(3)}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => GpsTrackingScreen(stateProvider: stateProvider)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'HELMET LED ARRAY',
                      value: helmet.nightModeLightsActive ? 'ACTIVE' : 'OFF',
                      unit: 'MODE',
                      icon: Icons.light_mode_outlined,
                      accentColor: helmet.nightModeLightsActive ? AppColors.statusWarning : AppColors.textSecondary,
                      subtitle: 'Night Visibility Safety',
                      onTap: () => stateProvider.toggleNightLights(!helmet.nightModeLightsActive),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Exhibition Demonstration Actions
              GlowContainer(
                borderColor: AppColors.borderHighlight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXHIBITION TEST CONTROLS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'TRIGGER CRASH',
                            variant: ButtonVariant.danger,
                            icon: Icons.warning_amber_rounded,
                            onPressed: () {
                              stateProvider.triggerSimulatedCrash();
                              _showSosModal(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            text: 'RADAR MAP',
                            variant: ButtonVariant.secondary,
                            icon: Icons.map_outlined,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => GpsTrackingScreen(stateProvider: stateProvider)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickMetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.cyanAccent),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
