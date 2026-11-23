import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';

/// Screen 12: Settings Screen for calibrating IoT thresholds and system behaviors.
class SettingsScreen extends StatelessWidget {
  final AppStateProvider stateProvider;

  const SettingsScreen({super.key, required this.stateProvider});

  @override
  Widget build(BuildContext context) {
    final helmet = stateProvider.helmetState;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'System Settings',
        subtitle: 'Sensor Calibration & Emergency Timing',
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency Timing Section
              const Text(
                'EMERGENCY SOS PARAMETERS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SettingsDropdownRow(
                      title: 'SOS Verification Countdown',
                      subtitle: 'Buffer time to cancel false positive crash alerts',
                      value: '${stateProvider.sosCountdownDuration} Seconds',
                      options: const ['5 Seconds', '10 Seconds', '15 Seconds', '20 Seconds'],
                      onChanged: (val) {
                        if (val != null) {
                          final secs = int.tryParse(val.split(' ').first) ?? 10;
                          stateProvider.updateSettings(sosDuration: secs);
                        }
                      },
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 24),
                    _SettingsSwitchRow(
                      title: 'Auditory Siren & Haptic Chime',
                      subtitle: 'Trigger acoustic buzzer on helmet during crash alerts',
                      value: stateProvider.soundAlertsEnabled,
                      onChanged: (val) => stateProvider.updateSettings(soundAlerts: val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sensor Threshold Calibration
              const Text(
                'HARDWARE THRESHOLD CALIBRATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SettingsInfoRow(
                      title: 'MQ-3 Alcohol Safe Limit',
                      value: '${AppConstants.alcoholSafetyThresholdPpm.toInt()} PPM',
                      subtitle: 'Exceeding this threshold activates ignition cut-off',
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 24),
                    _SettingsInfoRow(
                      title: 'MPU6050 Crash Impact Limit',
                      value: '${AppConstants.gForceAccidentThreshold} G',
                      subtitle: 'Forces above this trigger autonomous SOS dispatch',
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 24),
                    _SettingsInfoRow(
                      title: 'Roll/Pitch Tilt Fall Angle',
                      value: '±${AppConstants.tiltAngleAccidentThreshold.toInt()}°',
                      subtitle: 'Critical inclination angle for bike fall detection',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mode Toggles: Exhibition / Night Mode
              const Text(
                'OPERATION MODES & EXHIBITION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SettingsSwitchRow(
                      title: 'Exhibition Simulation Mode',
                      subtitle: 'Generates realistic IoT telemetry for indoor exhibitions',
                      value: stateProvider.simulationModeEnabled,
                      onChanged: (val) => stateProvider.updateSettings(simulationMode: val),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 24),
                    _SettingsSwitchRow(
                      title: 'Smart Night Safety Lighting',
                      subtitle: 'Auto-activates helmet rear LEDs during low-light riding',
                      value: stateProvider.autoNightModeEnabled,
                      onChanged: (val) => stateProvider.updateSettings(autoNightMode: val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              CustomButton(
                text: 'RESET TO EXHIBITION DEFAULTS',
                variant: ButtonVariant.outline,
                icon: Icons.restore,
                width: double.infinity,
                onPressed: () {
                  stateProvider.updateSettings(
                    sosDuration: 10,
                    soundAlerts: true,
                    simulationMode: true,
                    autoNightMode: true,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings restored to official exhibition standards.'),
                      backgroundColor: AppColors.backgroundCardLight,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.cyanAccent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SettingsDropdownRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdownRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButton<String>(
            value: value,
            dropdownColor: AppColors.backgroundCard,
            underline: const SizedBox.shrink(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyanAccent),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(opt),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SettingsInfoRow({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyanAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cyanAccent.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.cyanAccent, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
