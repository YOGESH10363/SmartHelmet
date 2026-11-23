import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/sensor_data.dart';
import '../common/glow_container.dart';
import '../common/status_badge.dart';

/// HelmetStatusCard displays the helmet wearing state and engine ignition relay.
class HelmetStatusCard extends StatelessWidget {
  final SensorData sensorData;
  final ValueChanged<bool>? onToggleHelmet;
  final VoidCallback? onToggleIgnition;

  const HelmetStatusCard({
    super.key,
    required this.sensorData,
    this.onToggleHelmet,
    this.onToggleIgnition,
  });

  @override
  Widget build(BuildContext context) {
    final isWorn = sensorData.isHelmetWorn;
    final isIgnitionOn = sensorData.isIgnitionUnlocked;

    return GlowContainer(
      borderColor: isWorn ? AppColors.statusSafe.withOpacity(0.3) : AppColors.statusEmergency.withOpacity(0.4),
      glowColor: isWorn ? AppColors.statusSafeGlow : AppColors.statusEmergencyGlow,
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
                        color: (isWorn ? AppColors.statusSafe : AppColors.statusEmergency).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.sports_motorsports,
                        color: isWorn ? AppColors.statusSafe : AppColors.statusEmergency,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HELMET INTERLOCK',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'IR Optical & Buckle Switch',
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
                label: isWorn ? 'WORN & SECURED' : 'NOT WORN',
                type: isWorn ? BadgeType.safe : BadgeType.emergency,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ignition interlock box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isIgnitionOn ? AppColors.statusSafe.withOpacity(0.3) : AppColors.statusEmergency.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isIgnitionOn ? Icons.lock_open : Icons.lock,
                  color: isIgnitionOn ? AppColors.statusSafe : AppColors.statusEmergency,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIgnitionOn ? 'ENGINE IGNITION: UNLOCKED' : 'ENGINE IGNITION: CUT-OFF LOCKED',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isIgnitionOn ? AppColors.statusSafe : AppColors.statusEmergency,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isIgnitionOn
                            ? 'Safety checklist validated. Rider authorized to start vehicle.'
                            : 'Ignition disabled by ESP32 relay until helmet is worn and rider is sober.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onToggleHelmet != null) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Simulation Control: ',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.8)),
                ),
                TextButton.icon(
                  onPressed: () => onToggleHelmet!(!isWorn),
                  icon: Icon(
                    isWorn ? Icons.remove_circle_outline : Icons.check_circle_outline,
                    size: 15,
                    color: AppColors.cyanAccent,
                  ),
                  label: Text(
                    isWorn ? 'Simulate Remove Helmet' : 'Simulate Wear Helmet',
                    style: const TextStyle(fontSize: 12, color: AppColors.cyanAccent, fontWeight: FontWeight.bold),
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
