import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/app_formatters.dart';
import '../common/glow_container.dart';

/// AccelerationChart renders a real-time live telemetry chart showing
/// continuous accelerometer and G-force waveforms.
class AccelerationChart extends StatelessWidget {
  final List<double> historyGForce;
  final List<double> historyAccelX;
  final List<double> historyAccelY;
  final DateTime timestamp;
  final bool isRealHardware;

  const AccelerationChart({
    super.key,
    required this.historyGForce,
    required this.historyAccelX,
    required this.historyAccelY,
    required this.timestamp,
    this.isRealHardware = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart, color: AppColors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'MPU6050 MOTION & ACCEL DYNAMICS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isRealHardware ? AppColors.statusSafe.withOpacity(0.15) : AppColors.cyanAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRealHardware ? 'LIVE ESP32 FEED' : 'DEMO STREAM',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isRealHardware ? AppColors.statusSafe : AppColors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Painted Multi-Waveform Canvas
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF070D1B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: _ChartPainter(
                  gForces: historyGForce,
                  accelX: historyAccelX,
                  accelY: historyAccelY,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Chart Legends and Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _LegendItem(color: AppColors.statusSafe, label: 'G-Force'),
                  const SizedBox(width: 10),
                  _LegendItem(color: AppColors.cyanAccent, label: 'Accel X'),
                  const SizedBox(width: 10),
                  _LegendItem(color: AppColors.blueLight, label: 'Accel Y'),
                ],
              ),
              Text(
                'Synced: ${AppFormatters.formatDateTime(timestamp)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> gForces;
  final List<double> accelX;
  final List<double> accelY;

  _ChartPainter({
    required this.gForces,
    required this.accelX,
    required this.accelY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid background lines
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);
    canvas.drawLine(Offset(0, midY - 35), Offset(size.width, midY - 35), gridPaint);
    canvas.drawLine(Offset(0, midY + 35), Offset(size.width, midY + 35), gridPaint);

    // 2. Draw Waveforms
    _drawSeries(canvas, size, gForces, AppColors.statusSafe, 1.0, 4.0);
    _drawSeries(canvas, size, accelX, AppColors.cyanAccent, 0.0, 5.0);
    _drawSeries(canvas, size, accelY, AppColors.blueLight, 0.0, 5.0);
  }

  void _drawSeries(Canvas canvas, Size size, List<double> data, Color color, double baseline, double maxScale) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final dx = size.width / (data.length - 1);
    final midY = size.height / 2;

    for (int i = 0; i < data.length; i++) {
      final normalizedValue = (data[i] - baseline) / maxScale;
      final y = (midY - (normalizedValue * (size.height * 0.4))).clamp(5.0, size.height - 5.0);
      final x = i * dx;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw active pulse dot at latest point
    final lastX = size.width;
    final lastNorm = (data.last - baseline) / maxScale;
    final lastY = (midY - (lastNorm * (size.height * 0.4))).clamp(5.0, size.height - 5.0);
    canvas.drawCircle(Offset(lastX, lastY), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
