import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/sensor_data.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_formatters.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/emergency/sos_countdown_dialog.dart';
import '../widgets/telemetry/acceleration_chart.dart';
import '../widgets/telemetry/gforce_meter.dart';
import '../widgets/telemetry/gyro_horizon_card.dart';
import 'device_connection_screen.dart';

/// Screen: Live Sensor Monitoring & Accident Intelligence Center (2nd Navigation Tab).
class AccidentMonitoringScreen extends StatelessWidget {
  final AppStateProvider stateProvider;

  const AccidentMonitoringScreen({super.key, required this.stateProvider});

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
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = stateProvider.telemetryData;
    final sensor = stateProvider.sensorData;
    final helmet = stateProvider.helmetState;
    final isDemoMode = stateProvider.isDemoMode;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Sensor & Crash Monitoring',
        subtitle: 'Live ESP32 Telemetry Subsystems',
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Data Provenance & Source Transparency Banner
              GlowContainer(
                borderColor: isDemoMode ? AppColors.cyanAccent.withOpacity(0.35) : AppColors.statusSafe.withOpacity(0.4),
                glowColor: isDemoMode ? AppColors.cyanGlow : AppColors.statusSafeGlow,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      isDemoMode ? Icons.hub_outlined : Icons.wifi_tethering,
                      color: isDemoMode ? AppColors.cyanAccent : AppColors.statusSafe,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isDemoMode ? 'DATA SOURCE: DEMO SIMULATOR' : 'DATA SOURCE: PHYSICAL ESP32 WI-FI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDemoMode ? AppColors.cyanAccent : AppColors.statusSafe,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDemoMode
                                ? 'Offline exhibition telemetry mode active. Hardware readings are simulated.'
                                : 'Live streaming via HTTP REST from ${stateProvider.esp32BaseUrl}',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DeviceConnectionScreen(stateProvider: stateProvider)),
                        );
                      },
                      child: Text(
                        isDemoMode ? 'CONNECT ESP32' : 'GATEWAY',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.cyanAccent),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Module 1: Helmet Wearing Detection Subsystem
              const Text(
                '1. HELMET WEARING & BUCKLE INTERLOCK',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (sensor.isHelmetWorn ? AppColors.statusSafe : AppColors.statusEmergency).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sports_motorsports,
                                color: sensor.isHelmetWorn ? AppColors.statusSafe : AppColors.statusEmergency,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sensor.isHelmetWorn ? 'CROWN OPTICAL IR: DETECTED' : 'CROWN OPTICAL IR: EMPTY',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: sensor.isHelmetWorn ? AppColors.statusSafe : AppColors.statusEmergency,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sensor.isStrapBuckled ? 'Chin Strap Microswitch: LATCHED' : 'Chin Strap Microswitch: OPEN',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: sensor.isHelmetWorn ? 'SECURED' : 'HAZARD',
                          type: sensor.isHelmetWorn ? BadgeType.safe : BadgeType.emergency,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hardware Channel: GPIO 18 & 19', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
                        Text('Last Sample: ${AppFormatters.formatDateTime(sensor.timestamp)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Module 2: MPU6050 Motion, Acceleration & Live Waveform Chart
              const Text(
                '2. MPU6050 MOTION & ACCELERATION WAVEFORM',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              // Live Strip Chart
              AccelerationChart(
                historyGForce: telemetry.historyGForce,
                historyAccelX: telemetry.historyAccelX,
                historyAccelY: telemetry.historyAccelY,
                timestamp: telemetry.timestamp,
                isRealHardware: !isDemoMode,
              ),

              const SizedBox(height: 14),

              // Artificial Horizon
              GyroHorizonCard(
                pitchAngle: telemetry.pitchAngle,
                rollAngle: telemetry.rollAngle,
              ),

              const SizedBox(height: 14),

              // G-Force Meter
              GForceMeter(
                currentGForce: telemetry.totalGForce,
                peakGForce: telemetry.lastImpactForceG,
              ),

              const SizedBox(height: 20),

              // 4. Module 3: GPS Geolocation & NEO-6M Availability
              const Text(
                '3. GPS NAVIGATION & SATELLITE FIX (NEO-6M)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.satellite_alt, color: AppColors.statusSafe, size: 22),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  telemetry.isGpsFixValid ? '3D FIX ACQUIRED' : 'SEARCHING FOR SATS',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: telemetry.isGpsFixValid ? AppColors.statusSafe : AppColors.statusWarning,
                                  ),
                                ),
                                Text(
                                  '${telemetry.gpsSatellites} Satellites Tracked • HDOP: 1.1',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: telemetry.isGpsFixValid ? 'LOCKED' : 'SEARCHING',
                          type: telemetry.isGpsFixValid ? BadgeType.safe : BadgeType.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LAT: ${telemetry.latitude.toStringAsFixed(5)}°N',
                            style: const TextStyle(fontSize: 11, color: AppColors.cyanAccent, fontFamily: 'monospace'),
                          ),
                          Text(
                            'LNG: ${telemetry.longitude.toStringAsFixed(5)}°E',
                            style: const TextStyle(fontSize: 11, color: AppColors.cyanAccent, fontFamily: 'monospace'),
                          ),
                          Text(
                            'ALT: ${telemetry.altitudeMeters.toInt()}m',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Module 4: GSM Module Status (SIM800L)
              const Text(
                '4. GSM CELLULAR DISTRESS GATEWAY (SIM800L)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusSafe.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cell_tower, color: AppColors.statusSafe, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sensor.gsmOperator,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const StatusBadge(label: 'READY', type: BadgeType.safe, showDot: false),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cellular Signal: ${sensor.gsmSignalBars}/5 Bars • SMS Dispatch Standby',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. Module 5: Alcohol Detection & Demonstration Notice
              const Text(
                '5. MQ-3 BREATH ALCOHOL MONITORING & SIMULATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                borderColor: sensor.isAlcoholSafe ? AppColors.statusSafe.withOpacity(0.35) : AppColors.statusEmergency.withOpacity(0.4),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_bar, color: AppColors.cyanAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isDemoMode ? 'SIMULATED ALCOHOL LEVEL' : 'REAL MQ-3 SENSOR READING',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: sensor.isAlcoholSafe ? 'SAFE' : 'LOCKED',
                          type: sensor.isAlcoholSafe ? BadgeType.safe : BadgeType.emergency,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          sensor.alcoholPpm.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: sensor.isAlcoholSafe ? AppColors.statusSafe : AppColors.statusEmergency,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('PPM (Limit: 200 PPM)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Clear distinction disclaimer banner
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderHighlight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.cyanAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isDemoMode
                                  ? 'Exhibition Demonstration: Reading is simulated via interactive test slider.'
                                  : 'Hardware reading streamed from physical ESP32 analog pin 34.',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Demo Alcohol Slider: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Expanded(
                          child: Slider(
                            value: sensor.alcoholPpm.clamp(0.0, 450.0),
                            min: 0.0,
                            max: 450.0,
                            activeColor: sensor.isAlcoholSafe ? AppColors.cyanAccent : AppColors.statusEmergency,
                            onChanged: (val) => stateProvider.setAlcoholPpm(val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Crash test trigger button for exhibition presentation
              CustomButton(
                text: 'SIMULATE CRASH & IMPACT TRIGGER',
                variant: ButtonVariant.danger,
                icon: Icons.personal_injury,
                width: double.infinity,
                onPressed: () {
                  stateProvider.triggerSimulatedCrash();
                  _showSosModal(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
