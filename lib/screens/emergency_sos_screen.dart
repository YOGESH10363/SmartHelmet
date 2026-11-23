import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/incident_report.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_formatters.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';
import 'emergency_contact_config_screen.dart';
import 'emergency_warning_screen.dart';

/// Screen 10: Emergency SOS Command Center with confirmation guard and test drill mode.
class EmergencySosScreen extends StatefulWidget {
  final AppStateProvider stateProvider;

  const EmergencySosScreen({super.key, required this.stateProvider});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  void _confirmAndTriggerManualSos() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.statusEmergency),
              SizedBox(width: 8),
              Text('Confirm Manual SOS', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            widget.stateProvider.isTestEmergencyMode
                ? 'Initiate a simulated emergency drill? No cellular SMS will be sent.'
                : 'ACTIVATE EMERGENCY DISTRESS BROADCAST?\n\nThis will trigger the helmet alarm and initiate emergency SMS dispatch with your live GPS location to all registered contacts.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            CustomButton(
              text: 'CONFIRM DISTRESS',
              variant: ButtonVariant.danger,
              height: 42,
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.stateProvider.triggerManualSos();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmergencyWarningScreen(stateProvider: widget.stateProvider),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final helmet = widget.stateProvider.helmetState;
    final contacts = widget.stateProvider.emergencyContacts;
    final telemetry = widget.stateProvider.telemetryData;
    final user = widget.stateProvider.userProfile;
    final isTestMode = widget.stateProvider.isTestEmergencyMode;
    final activeReport = widget.stateProvider.activeEmergencyIncident;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Emergency SOS Central',
        subtitle: 'Autonomous Rescue Dispatch & Safety Mesh',
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test Emergency Mode Toggle Bar
              GlowContainer(
                borderColor: isTestMode ? AppColors.cyanAccent.withOpacity(0.4) : AppColors.borderSubtle,
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.biotech_outlined,
                          color: isTestMode ? AppColors.cyanAccent : AppColors.textMuted,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TEST EMERGENCY DRILL MODE',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTestMode
                                  ? 'Safe Sandbox: No real SMS transmitted'
                                  : 'Production: Real SIM800L cellular dispatch',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isTestMode ? AppColors.cyanAccent : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isTestMode,
                      activeColor: AppColors.cyanAccent,
                      onChanged: (val) => widget.stateProvider.setTestEmergencyMode(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Manual SOS Trigger Button with Confirmation Notice
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _confirmAndTriggerManualSos,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.emergencyGradient,
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.statusEmergencyGlow,
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sos_rounded, size: 58, color: Colors.white),
                            SizedBox(height: 4),
                            Text(
                              'TAP TO ACTIVATE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Requires Confirmation',
                              style: TextStyle(fontSize: 9.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Double-confirmation prevents accidental triggers while riding.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active Incident Status Card (if an alert was triggered)
              if (activeReport != null) ...[
                GlowContainer(
                  borderColor: AppColors.statusEmergency.withOpacity(0.4),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CURRENT ALERT: ${activeReport.id}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusEmergency, fontFamily: 'monospace'),
                          ),
                          StatusBadge(label: activeReport.deliveryStatus.name.toUpperCase(), type: BadgeType.emergency),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeReport.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeReport.description,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'OPEN DISTRESS MONITOR & LOGS',
                        variant: ButtonVariant.primary,
                        height: 38,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EmergencyWarningScreen(stateProvider: widget.stateProvider),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Emergency SMS Payload Preview
              GlowContainer(
                borderColor: AppColors.borderSubtle,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AUTOMATED GSM EMERGENCY SMS TEMPLATE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
                        ),
                        Icon(Icons.sms, size: 16, color: AppColors.cyanAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        'EMERGENCY ALERT: Smart Helmet 2.0 registered high-impact crash for rider ${user.fullName} (${user.bloodGroup}). Live GPS Coordinates: https://maps.google.com/?q=${telemetry.latitude},${telemetry.longitude}. Immediate medical assistance required.',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.4, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Emergency Contacts Quick Directory Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RESCUE CONTACTS (${contacts.length})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EmergencyContactConfigScreen(stateProvider: widget.stateProvider),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, size: 16, color: AppColors.cyanAccent),
                    label: const Text('Configure Recipients', style: TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Contacts Summary List
              ...contacts.map((contact) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: contact.isPrimary ? AppColors.statusEmergency.withOpacity(0.3) : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          contact.isPrimary ? Icons.star : Icons.person,
                          color: contact.isPrimary ? AppColors.statusEmergency : AppColors.cyanAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('${contact.relationship} • ${contact.phone}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (contact.isPrimary)
                          const StatusBadge(label: 'PRIMARY', type: BadgeType.emergency, showDot: false),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
