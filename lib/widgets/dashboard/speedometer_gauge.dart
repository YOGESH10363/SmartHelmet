import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

/// SpeedometerGauge renders a circular digital gauge with animated sweep.
class SpeedometerGauge extends StatelessWidget {
  final double currentSpeed;
  final double maxSpeed;
  final double speedLimit;

  const SpeedometerGauge({
    super.key,
    required this.currentSpeed,
    this.maxSpeed = 120.0,
    this.speedLimit = AppConstants.overSpeedLimitKmh,
  });

  @override
  Widget build(BuildContext context) {
    final isOverSpeed = currentSpeed > speedLimit;

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Custom Painted Speedometer Arc
            CustomPaint(
              size: const Size(220, 220),
              painter: _SpeedometerPainter(
                speed: currentSpeed,
                maxSpeed: maxSpeed,
                speedLimit: speedLimit,
              ),
            ),

            // Inner readout
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CURRENT SPEED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentSpeed.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: isOverSpeed ? AppColors.statusEmergency : AppColors.cyanAccent,
                        fontFamily: 'monospace',
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'KM/H',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (isOverSpeed) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusEmergency.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.statusEmergency, width: 0.8),
                    ),
                    child: const Text(
                      'OVER SPEED LIMIT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusEmergency,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'LIMIT: ${speedLimit.toInt()} KM/H',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final double speedLimit;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.speedLimit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    const startAngle = 135.0 * (pi / 180.0);
    const sweepAngle = 270.0 * (pi / 180.0);

    // 1. Background Arc Track
    final trackPaint = Paint()
      ..color = AppColors.backgroundCardLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // 2. Active Speed Sweep
    final normalized = (speed / maxSpeed).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * normalized;

    final isOverSpeed = speed > speedLimit;

    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: isOverSpeed
            ? const [AppColors.cyanAccent, AppColors.statusWarning, AppColors.statusEmergency]
            : const [AppColors.electricBlue, AppColors.cyanAccent],
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // 3. Ticks around perimeter
    final tickPaint = Paint()
      ..color = AppColors.borderHighlight
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 12; i++) {
      final angle = startAngle + (sweepAngle * (i / 12));
      final inner = Offset(center.dx + (radius - 18) * cos(angle), center.dy + (radius - 18) * sin(angle));
      final outer = Offset(center.dx + (radius - 12) * cos(angle), center.dy + (radius - 12) * sin(angle));
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.speedLimit != speedLimit;
  }
}
