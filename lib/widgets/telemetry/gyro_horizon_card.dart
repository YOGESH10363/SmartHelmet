import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../common/glow_container.dart';

/// GyroHorizonCard renders a custom-painted artificial horizon showing
/// the helmet's 3D tilt angles (Pitch & Roll) from the MPU6050 sensor.
class GyroHorizonCard extends StatelessWidget {
  final double pitchAngle;
  final double rollAngle;

  const GyroHorizonCard({
    super.key,
    required this.pitchAngle,
    required this.rollAngle,
  });

  @override
  Widget build(BuildContext context) {
    final isDangerousTilt = pitchAngle.abs() >= AppConstants.tiltAngleAccidentThreshold ||
        rollAngle.abs() >= AppConstants.tiltAngleAccidentThreshold;

    return GlowContainer(
      borderColor: isDangerousTilt ? AppColors.statusEmergency.withOpacity(0.4) : AppColors.cyanAccent.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.screen_rotation_alt, color: AppColors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'GYRO ARTIFICIAL HORIZON (MPU6050)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDangerousTilt ? AppColors.statusEmergency.withOpacity(0.2) : AppColors.statusSafe.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDangerousTilt ? 'FALL DETECTED' : 'UPRIGHT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDangerousTilt ? AppColors.statusEmergency : AppColors.statusSafe,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Custom Painted Horizon Sphere
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderHighlight, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyanGlow,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: const Size(110, 110),
                    painter: _HorizonPainter(
                      pitch: pitchAngle,
                      roll: rollAngle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Digital Pitch & Roll Readouts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AngleRow(
                      label: 'PITCH (ELEVATION)',
                      angle: pitchAngle,
                      color: AppColors.cyanAccent,
                    ),
                    const SizedBox(height: 12),
                    _AngleRow(
                      label: 'ROLL (LEAN TILT)',
                      angle: rollAngle,
                      color: AppColors.blueLight,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Max safe lean: ±65°\nExceeding angle initiates accident countdown.',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AngleRow extends StatelessWidget {
  final String label;
  final double angle;
  final Color color;

  const _AngleRow({
    required this.label,
    required this.angle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '${angle >= 0 ? '+' : ''}${angle.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _HorizonPainter extends CustomPainter {
  final double pitch;
  final double roll;

  _HorizonPainter({required this.pitch, required this.roll});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Rotate canvas by roll angle
    canvas.rotate(roll * (pi / 180.0));

    // Pitch shift (vertical translation)
    final pitchOffset = (pitch / 90.0) * radius;

    // Sky paint (Top)
    final skyPaint = Paint()..color = const Color(0xFF0D3268);
    canvas.drawRect(
      Rect.fromLTRB(-radius * 2, -radius * 2, radius * 2, pitchOffset),
      skyPaint,
    );

    // Ground paint (Bottom)
    final groundPaint = Paint()..color = const Color(0xFF1E2838);
    canvas.drawRect(
      Rect.fromLTRB(-radius * 2, pitchOffset, radius * 2, radius * 2),
      groundPaint,
    );

    // Horizon Line
    final horizonPaint = Paint()
      ..color = AppColors.cyanAccent
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(-radius, pitchOffset), Offset(radius, pitchOffset), horizonPaint);

    canvas.restore();

    // Crosshairs overlay (fixed at center)
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(center.dx - 18, center.dy), Offset(center.dx - 6, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + 6, center.dy), Offset(center.dx + 18, center.dy), crossPaint);
    canvas.drawCircle(center, 3, Paint()..color = AppColors.cyanAccent);
  }

  @override
  bool shouldRepaint(covariant _HorizonPainter oldDelegate) {
    return oldDelegate.pitch != pitch || oldDelegate.roll != roll;
  }
}
