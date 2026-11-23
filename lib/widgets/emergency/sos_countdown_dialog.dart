import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/incident_report.dart';
import '../common/custom_button.dart';

/// SosCountdownDialog shows a modal countdown when a crash or SOS trigger occurs.
class SosCountdownDialog extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final IncidentReport? incident;
  final VoidCallback onCancel;
  final VoidCallback onDispatchNow;

  const SosCountdownDialog({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = 10,
    this.incident,
    required this.onCancel,
    required this.onDispatchNow,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.statusEmergency, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emergency Alert Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusEmergency.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.statusEmergency),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.statusEmergency, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'CRITICAL SAFETY SOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.statusEmergency,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              incident?.title ?? 'Accident / Severe Impact Detected!',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Automated emergency dispatch will transmit live GPS coordinates and impact telemetry to contacts if not cancelled.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Pulsating Countdown Circle
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.backgroundSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statusEmergency),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$remainingSeconds',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.statusEmergency,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        'SECONDS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Cancel Button
            CustomButton(
              text: "I'M SAFE - CANCEL ALERT",
              variant: ButtonVariant.primary,
              icon: Icons.check_circle_outline,
              width: double.infinity,
              onPressed: onCancel,
            ),
            const SizedBox(height: 12),

            // Immediate Dispatch Button
            CustomButton(
              text: 'SEND DISTRESS NOW',
              variant: ButtonVariant.danger,
              icon: Icons.send_rounded,
              width: double.infinity,
              onPressed: onDispatchNow,
            ),
          ],
        ),
      ),
    );
  }
}
