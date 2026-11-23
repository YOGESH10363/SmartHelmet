import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../common/glow_container.dart';

/// GForceMeter displays real-time accelerometer impact force in Gs.
class GForceMeter extends StatelessWidget {
  final double currentGForce;
  final double peakGForce;

  const GForceMeter({
    super.key,
    required this.currentGForce,
    required this.peakGForce,
  });

  @override
  Widget build(BuildContext context) {
    final isImpactCritical = currentGForce >= AppConstants.gForceAccidentThreshold;
    final color = isImpactCritical
        ? AppColors.statusEmergency
        : (currentGForce > 2.5 ? AppColors.statusWarning : AppColors.cyanAccent);

    return GlowContainer(
      borderColor: isImpactCritical ? AppColors.statusEmergency.withOpacity(0.4) : AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.vibration, color: AppColors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'IMPACT FORCE & G-METER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                'PEAK: ${peakGForce.toStringAsFixed(2)} G',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currentGForce.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'G (EARTH GRAVITY EQ.)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal G Meter Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (currentGForce / 8.0).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppColors.backgroundSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 G (Freefall)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('1.0 G (Rest)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('4.2 G (Crash Threshold)', style: TextStyle(fontSize: 10, color: AppColors.statusEmergency, fontWeight: FontWeight.bold)),
              Text('8.0 G', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
