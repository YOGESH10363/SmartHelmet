import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/sensor_data.dart';
import '../common/glow_container.dart';
import '../common/status_badge.dart';

/// AlcoholStatusCard displays the MQ-3 breath alcohol detection levels and safety thresholds.
class AlcoholStatusCard extends StatelessWidget {
  final SensorData sensorData;
  final ValueChanged<double>? onPpmChanged;

  const AlcoholStatusCard({
    super.key,
    required this.sensorData,
    this.onPpmChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSafe = sensorData.isAlcoholSafe;
    final ppm = sensorData.alcoholPpm;
    final threshold = sensorData.alcoholThresholdPpm;

    Color stateColor;
    BadgeType badgeType;
    String statusTitle;

    if (ppm < 100) {
      stateColor = AppColors.statusSafe;
      badgeType = BadgeType.safe;
      statusTitle = 'ZERO / SOBER';
    } else if (isSafe) {
      stateColor = AppColors.statusWarning;
      badgeType = BadgeType.warning;
      statusTitle = 'TRACE ALCOHOL';
    } else {
      stateColor = AppColors.statusEmergency;
      badgeType = BadgeType.emergency;
      statusTitle = 'INTOXICATED (LOCKOUT)';
    }

    return GlowContainer(
      borderColor: stateColor.withOpacity(0.35),
      glowColor: isSafe ? null : AppColors.statusEmergencyGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stateColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_bar, color: stateColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALCOHOL INTERLOCK (MQ-3)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Electrochemical Breathalyzer',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: statusTitle,
                type: badgeType,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // PPM readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        ppm.toStringAsFixed(1),
                        style: AppTextStyles.telemetryValue.copyWith(
                          fontSize: 26,
                          color: stateColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('PPM', style: AppTextStyles.telemetryUnit),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'MAX: ${threshold.toInt()} PPM',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (ppm / 500.0).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.backgroundSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(stateColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isSafe
                ? 'Breath analysis normal. Rider is within legal and safe limits.'
                : 'CRITICAL ALERT: Alcohol exceeds safe threshold! Vehicle ignition locked to prevent DUI.',
            style: TextStyle(
              fontSize: 11,
              color: isSafe ? AppColors.textSecondary : AppColors.statusEmergency,
              fontWeight: isSafe ? FontWeight.normal : FontWeight.w700,
            ),
          ),
          if (onPpmChanged != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Demo Alcohol Slider:',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbColor: AppColors.cyanAccent,
                      activeTrackColor: AppColors.cyanAccent,
                      inactiveTrackColor: AppColors.backgroundSecondary,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: ppm.clamp(0.0, 450.0),
                      min: 0.0,
                      max: 450.0,
                      onChanged: onPpmChanged,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
