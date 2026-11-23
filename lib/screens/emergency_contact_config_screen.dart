import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/emergency_contact.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';

/// Screen: Emergency Contact Configuration & Directory.
class EmergencyContactConfigScreen extends StatefulWidget {
  final AppStateProvider stateProvider;

  const EmergencyContactConfigScreen({super.key, required this.stateProvider});

  @override
  State<EmergencyContactConfigScreen> createState() => _EmergencyContactConfigScreenState();
}

class _EmergencyContactConfigScreenState extends State<EmergencyContactConfigScreen> {
  void _showContactEditorDialog({EmergencyContact? existing}) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final relationController = TextEditingController(text: existing?.relationship ?? 'Guardian');
    bool isPrimary = existing?.isPrimary ?? false;
    bool notifySms = existing?.notifyViaSms ?? true;
    bool notifyCall = existing?.notifyViaCall ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: Text(
                isEditing ? 'Edit Emergency Contact' : 'Add Rescue Contact',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Contact Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        hintText: '+91 98XXX XXXXX',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: relationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Relationship / Role',
                        hintText: 'Father, Sister, Doctor, Police',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Primary Contact', style: TextStyle(fontSize: 13, color: Colors.white)),
                      subtitle: const Text('First recipient dialed during trauma alert', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      value: isPrimary,
                      activeColor: AppColors.cyanAccent,
                      onChanged: (val) => setDialogState(() => isPrimary = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send Emergency SMS', style: TextStyle(fontSize: 13, color: Colors.white)),
                      subtitle: const Text('Include in automated GSM SMS broadcast', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      value: notifySms,
                      activeColor: AppColors.cyanAccent,
                      onChanged: (val) => setDialogState(() => notifySms = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                CustomButton(
                  text: isEditing ? 'Save Changes' : 'Add Contact',
                  height: 42,
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    if (name.isNotEmpty && phone.isNotEmpty) {
                      final updated = EmergencyContact(
                        id: existing?.id ?? 'cnt-${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        phone: phone,
                        relationship: relationController.text.trim(),
                        isPrimary: isPrimary,
                        notifyViaSms: notifySms,
                        notifyViaCall: notifyCall,
                      );

                      if (isEditing) {
                        widget.stateProvider.updateEmergencyContact(updated);
                      } else {
                        widget.stateProvider.addEmergencyContact(updated);
                      }
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.stateProvider.emergencyContacts;
    final helmet = widget.stateProvider.helmetState;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Emergency Contact Setup',
        subtitle: 'Configure automated SMS recipients',
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description card
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.contact_emergency, color: AppColors.statusEmergency, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESCUE DISPATCH RECIPIENTS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'When a crash is confirmed, the ESP32 SIM800L module dispatches automated distress SMS messages with live GPS coordinates to all active contacts below.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REGISTERED CONTACTS (${contacts.length})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
                  ),
                  TextButton.icon(
                    onPressed: () => _showContactEditorDialog(),
                    icon: const Icon(Icons.add, size: 16, color: AppColors.cyanAccent),
                    label: const Text('Add Recipient', style: TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (contacts.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No emergency contacts configured yet.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              ] else ...[
                ...contacts.map((contact) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlowContainer(
                      borderColor: contact.isPrimary ? AppColors.statusEmergency.withOpacity(0.4) : AppColors.borderSubtle,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (contact.isPrimary ? AppColors.statusEmergency : AppColors.cyanAccent).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              contact.isPrimary ? Icons.star : Icons.person,
                              color: contact.isPrimary ? AppColors.statusEmergency : AppColors.cyanAccent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      contact.name,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    if (contact.isPrimary) ...[
                                      const SizedBox(width: 8),
                                      const StatusBadge(label: 'PRIMARY', type: BadgeType.emergency, showDot: false),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${contact.relationship} • ${contact.phone}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.sms, size: 12, color: contact.notifyViaSms ? AppColors.statusSafe : AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      contact.notifyViaSms ? 'SMS Enabled' : 'SMS Disabled',
                                      style: TextStyle(fontSize: 10, color: contact.notifyViaSms ? AppColors.statusSafe : AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.cyanAccent, size: 20),
                            onPressed: () => _showContactEditorDialog(existing: contact),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                            onPressed: () => widget.stateProvider.removeEmergencyContact(contact.id),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Emergency Numbers Quick Add Card
              const Text(
                'NATIONAL EMERGENCY HOTLINE SHORTCUTS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HotlineCard(
                      number: '112',
                      service: 'Police & Unified Rescue',
                      icon: Icons.local_police_outlined,
                      onAdd: () {
                        widget.stateProvider.addEmergencyContact(
                          const EmergencyContact(
                            id: 'hotline-112',
                            name: 'National Emergency 112',
                            phone: '112',
                            relationship: 'Police Dispatch',
                            notifyViaSms: true,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HotlineCard(
                      number: '108',
                      service: 'Ambulance Trauma Care',
                      icon: Icons.local_hospital_outlined,
                      onAdd: () {
                        widget.stateProvider.addEmergencyContact(
                          const EmergencyContact(
                            id: 'hotline-108',
                            name: 'Ambulance 108',
                            phone: '108',
                            relationship: 'Trauma Emergency',
                            notifyViaSms: true,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotlineCard extends StatelessWidget {
  final String number;
  final String service;
  final IconData icon;
  final VoidCallback onAdd;

  const _HotlineCard({
    required this.number,
    required this.service,
    required this.icon,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.statusEmergency, size: 20),
              Text(
                number,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.statusEmergency, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(service, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          CustomButton(
            text: '+ ADD HOTLINE',
            variant: ButtonVariant.outline,
            height: 32,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
