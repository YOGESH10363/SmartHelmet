import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';

/// Screen 7: Helmet Safety Screen (Pre-Ride Checklist & Safety Interlock Engine).
class HelmetSafetyScreen extends StatelessWidget {
  final AppStateProvider stateProvider;

  const HelmetSafetyScreen({super.key, required this.stateProvider});

  @override
  Widget build(BuildContext context) {
    final sensor = stateProvider.sensorData;
    final helmet = stateProvider.helmetState;
    final isSafetyCompliant = sensor.isSafetyCompliant;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Safety Interlock System',
        subtitle: 'Pre-Ride Checklist & Ignition Guard',
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master Interlock Decision Banner
              GlowContainer(
                borderColor: isSafetyCompliant ? AppColors.statusSafe.withOpacity(0.4) : AppColors.statusEmergency.withOpacity(0.4),
                glowColor: isSafetyCompliant ? AppColors.statusSafeGlow : AppColors.statusEmergencyGlow,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isSafetyCompliant ? AppColors.statusSafe : AppColors.statusEmergency).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSafetyCompliant ? Icons.verified_user : Icons.gpp_bad,
                            color: isSafetyCompliant ? AppColors.statusSafe : AppColors.statusEmergency,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSafetyCompliant ? 'VEHICLE IGNITION AUTHORIZED' : 'VEHICLE IGNITION LOCKED',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isSafetyCompliant ? AppColors.statusSafe : AppColors.statusEmergency,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSafetyCompliant
                                    ? 'All physical & physiological checks validated. Ignition cut-off relay disengaged.'
                                    : 'Safety violation detected! Relay circuit is OPEN to inhibit motorcycle starter motor.',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Checklist Section
              const Text(
                'PRE-RIDE INTERLOCK CHECKLIST',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              _ChecklistItem(
                title: 'Helmet Optical IR Proximity',
                subtitle: sensor.isHelmetWorn
                    ? 'Infrared sensor verifies head placement inside crown'
                    : 'Helmet not detected on rider head',
                isPassed: sensor.isHelmetWorn,
                icon: Icons.sports_motorsports,
              ),
              const SizedBox(height: 10),

              _ChecklistItem(
                title: 'Chin Strap Micro-Switch Buckle',
                subtitle: sensor.isStrapBuckled
                    ? 'Magnetic buckle switch securely fastened'
                    : 'Chin strap unlatched - high ejection hazard',
                isPassed: sensor.isStrapBuckled,
                icon: Icons.link,
              ),
              const SizedBox(height: 10),

              _ChecklistItem(
                title: 'MQ-3 Alcohol Gas Breathalyzer',
                subtitle: sensor.isAlcoholSafe
                    ? 'Measured: ${sensor.alcoholPpm.toStringAsFixed(1)} PPM (Limit < 200 PPM)'
                    : 'INTOXICATION: ${sensor.alcoholPpm.toStringAsFixed(1)} PPM (Exceeds 200 PPM Limit)',
                isPassed: sensor.isAlcoholSafe,
                icon: Icons.local_bar,
              ),
              const SizedBox(height: 10),

              _ChecklistItem(
                title: '12V Motorcycle Starter Relay',
                subtitle: sensor.isIgnitionUnlocked
                    ? 'Relay energized: Engine start circuit enabled'
                    : 'Relay tripped: Engine start circuit grounded & isolated',
                isPassed: sensor.isIgnitionUnlocked,
                icon: Icons.power,
              ),

              const SizedBox(height: 24),

              // Manual Testing & Demonstration Panel for Exhibition
              GlowContainer(
                borderColor: AppColors.borderHighlight,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HARDWARE SIMULATION TESTING CONTROLS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 14),

                    // Helmet wearing toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Helmet IR Sensor State', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            Text('Simulates wearing or removing helmet', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        Switch(
                          value: sensor.isHelmetWorn,
                          activeColor: AppColors.cyanAccent,
                          onChanged: (val) => stateProvider.toggleHelmetWorn(val),
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.borderSubtle, height: 24),

                    // Alcohol Level Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Simulate Alcohol Concentration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            Text(
                              '${sensor.alcoholPpm.toStringAsFixed(0)} PPM',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: sensor.isAlcoholSafe ? AppColors.statusSafe : AppColors.statusEmergency,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: sensor.alcoholPpm.clamp(0.0, 450.0),
                          min: 0.0,
                          max: 450.0,
                          activeColor: sensor.isAlcoholSafe ? AppColors.cyanAccent : AppColors.statusEmergency,
                          onChanged: (v) => stateProvider.setAlcoholPpm(v),
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.borderSubtle, height: 24),

                    // Manual Relay Override Button
                    CustomButton(
                      text: sensor.isIgnitionUnlocked ? 'MANUALLY CUT IGNITION RELAY' : 'RELEASE IGNITION RELAY',
                      variant: sensor.isIgnitionUnlocked ? ButtonVariant.danger : ButtonVariant.outline,
                      icon: Icons.electric_bolt,
                      width: double.infinity,
                      onPressed: () {
                        stateProvider.toggleIgnitionRelay(!sensor.isIgnitionUnlocked);
                      },
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

class _ChecklistItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isPassed;
  final IconData icon;

  const _ChecklistItem({
    required this.title,
    required this.subtitle,
    required this.isPassed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed ? AppColors.statusSafe.withOpacity(0.3) : AppColors.statusEmergency.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            color: isPassed ? AppColors.statusSafe : AppColors.statusEmergency,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: isPassed ? 'PASS' : 'FAIL',
            type: isPassed ? BadgeType.safe : BadgeType.emergency,
            showDot: false,
          ),
        ],
      ),
    );
  }
}
