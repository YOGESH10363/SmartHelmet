import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/incident_report.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_formatters.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';

/// Screen: Full-Screen Emergency Warning & Distress Dispatch Management.
class EmergencyWarningScreen extends StatelessWidget {
  final AppStateProvider stateProvider;
  final IncidentReport? incident;

  const EmergencyWarningScreen({
    super.key,
    required this.stateProvider,
    this.incident,
  });

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Cancel Emergency Alert?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to cancel this emergency alert? This will stop automated emergency dispatch to rescue contacts.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Active', style: TextStyle(color: AppColors.textSecondary)),
            ),
            CustomButton(
              text: 'Yes, Cancel Alarm',
              variant: ButtonVariant.danger,
              height: 42,
              onPressed: () {
                stateProvider.cancelEmergencyCountdown();
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _acknowledgeEvent(BuildContext context) {
    stateProvider.acknowledgeActiveIncident(acknowledgedBy: 'Rider / On-scene Confirmed');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incident acknowledged. Status updated in safety blackbox.'),
        backgroundColor: AppColors.statusSafe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeReport = incident ?? stateProvider.activeEmergencyIncident;
    final isCountdownActive = stateProvider.isSosCountdownActive;
    final remainingSecs = stateProvider.sosRemainingSeconds;
    final isTestMode = activeReport?.isTestEmergency ?? stateProvider.isTestEmergencyMode;

    final deliveryStatus = activeReport?.deliveryStatus ?? (isCountdownActive ? AlertDeliveryStatus.detected : AlertDeliveryStatus.delivered);

    Color statusColor;
    String statusTitle;
    BadgeType badgeType;

    switch (deliveryStatus) {
      case AlertDeliveryStatus.detected:
        statusColor = AppColors.statusWarning;
        statusTitle = 'COLLISION DETECTED (VERIFYING)';
        badgeType = BadgeType.warning;
        break;
      case AlertDeliveryStatus.pending:
        statusColor = AppColors.statusWarning;
        statusTitle = 'DISPATCH QUEUED (PENDING GSM)';
        badgeType = BadgeType.warning;
        break;
      case AlertDeliveryStatus.sent:
        statusColor = AppColors.cyanAccent;
        statusTitle = 'TRANSMITTED TO SIM800L MODEM';
        badgeType = BadgeType.info;
        break;
      case AlertDeliveryStatus.delivered:
        statusColor = AppColors.statusSafe;
        statusTitle = isTestMode ? 'TEST DRILL COMPLETED' : 'DELIVERED (+CMGS NETWORK ACK)';
        badgeType = BadgeType.safe;
        break;
      case AlertDeliveryStatus.failed:
        statusColor = AppColors.statusEmergency;
        statusTitle = 'DELIVERY FAILED (NO SIGNAL / TIMEOUT)';
        badgeType = BadgeType.emergency;
        break;
      case AlertDeliveryStatus.cancelled:
        statusColor = AppColors.statusOffline;
        statusTitle = 'CANCELLED (FALSE ALARM)';
        badgeType = BadgeType.offline;
        break;
      case AlertDeliveryStatus.acknowledged:
        statusColor = AppColors.statusSafe;
        statusTitle = 'ACKNOWLEDGED & RESOLVED';
        badgeType = BadgeType.safe;
        break;
    }

    final contactsLogs = activeReport?.deliveryLogs ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Emergency Distress Monitor'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test Drill Mode Banner
              if (isTestMode) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cyanAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.cyanAccent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'TEST EMERGENCY DRILL MODE ACTIVE\nSimulated drill sandbox. No cellular SMS will be billed or dispatched.',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Critical Alert State Banner
              GlowContainer(
                borderColor: statusColor.withOpacity(0.5),
                glowColor: statusColor.withOpacity(0.2),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCountdownActive ? Icons.timer : Icons.warning_rounded,
                            color: statusColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusTitle,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeReport?.title ?? 'Accident / High-G Impact Triggered',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(label: deliveryStatus.name.toUpperCase(), type: badgeType),
                      ],
                    ),

                    if (isCountdownActive) ...[
                      const SizedBox(height: 20),
                      // Countdown Bar
                      Column(
                        children: [
                          Text(
                            '$remainingSecs SECONDS REMAINING TO CANCEL',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusEmergency),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (remainingSecs / stateProvider.sosCountdownDuration).clamp(0.0, 1.0),
                            backgroundColor: AppColors.backgroundSecondary,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statusEmergency),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Accident Telemetry & Exact Timestamp
              const Text(
                'INCIDENT METRICS & TIME OF OCCURRENCE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _IncidentRow(
                      label: 'Exact Timestamp',
                      value: activeReport != null
                          ? '${AppFormatters.formatDate(activeReport.timestamp)} at ${AppFormatters.formatDateTime(activeReport.timestamp)}'
                          : AppFormatters.formatDateTime(DateTime.now()),
                      icon: Icons.access_time_filled,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 20),
                    _IncidentRow(
                      label: 'GPS Coordinates',
                      value: activeReport != null && activeReport.hasGpsCoordinates
                          ? '${activeReport.latitude.toStringAsFixed(5)}°N, ${activeReport.longitude.toStringAsFixed(5)}°E'
                          : 'GPS Fix Searching (Last Known Available)',
                      icon: Icons.place,
                      valueColor: activeReport != null && activeReport.hasGpsCoordinates ? AppColors.cyanAccent : AppColors.statusWarning,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 20),
                    _IncidentRow(
                      label: 'Peak Impact Force',
                      value: '${activeReport?.peakGForce.toStringAsFixed(2) ?? '6.40'} G (Exceeds 4.2 G Limit)',
                      icon: Icons.vibration,
                      valueColor: AppColors.statusEmergency,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 20),
                    _IncidentRow(
                      label: 'Pre-Impact Speed',
                      value: '${activeReport?.speedKmh.toStringAsFixed(1) ?? '45.0'} km/h',
                      icon: Icons.speed,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // SMS Delivery Status per Recipient (SIM800L GSM Network Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CELLULAR GSM SMS DELIVERY REPORT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
                  ),
                  Text(
                    isTestMode ? 'SIMULATED LOG' : 'SIM800L MODEM',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (contactsLogs.isEmpty) ...[
                GlowContainer(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        isCountdownActive
                            ? 'Awaiting countdown expiration before GSM SMS dispatch.'
                            : 'No dispatch logs available.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...contactsLogs.map((log) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            log.status == AlertDeliveryStatus.delivered
                                ? Icons.check_circle
                                : (log.status == AlertDeliveryStatus.failed ? Icons.error_outline : Icons.schedule),
                            color: log.status == AlertDeliveryStatus.delivered
                                ? AppColors.statusSafe
                                : (log.status == AlertDeliveryStatus.failed ? AppColors.statusEmergency : AppColors.statusWarning),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.contactName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${log.phone} • ${log.networkResponse ?? ''}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: log.status.name.toUpperCase(),
                            type: log.status == AlertDeliveryStatus.delivered
                                ? BadgeType.safe
                                : (log.status == AlertDeliveryStatus.failed ? BadgeType.emergency : BadgeType.warning),
                            showDot: false,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Action Buttons: Acknowledgement & Cancellation
              if (deliveryStatus != AlertDeliveryStatus.acknowledged && deliveryStatus != AlertDeliveryStatus.cancelled) ...[
                CustomButton(
                  text: 'ACKNOWLEDGE INCIDENT & CONFIRM SAFETY',
                  variant: ButtonVariant.primary,
                  icon: Icons.thumb_up_alt_outlined,
                  width: double.infinity,
                  onPressed: () => _acknowledgeEvent(context),
                ),
                const SizedBox(height: 10),
              ],

              if (isCountdownActive) ...[
                CustomButton(
                  text: 'CANCEL FALSE ALARM',
                  variant: ButtonVariant.danger,
                  icon: Icons.cancel_outlined,
                  width: double.infinity,
                  onPressed: () => _showCancelConfirmation(context),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _IncidentRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
