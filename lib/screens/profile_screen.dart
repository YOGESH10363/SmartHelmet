import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/user_profile.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import '../widgets/common/status_badge.dart';
import 'about_project_screen.dart';
import 'device_connection_screen.dart';
import 'emergency_contact_config_screen.dart';
import 'emergency_sos_screen.dart';
import 'helmet_safety_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

/// Screen: Profile and System Management (5th Navigation Hub).
class ProfileScreen extends StatelessWidget {
  final AppStateProvider stateProvider;

  const ProfileScreen({super.key, required this.stateProvider});

  void _showEditProfileDialog(BuildContext context) {
    final user = stateProvider.userProfile;
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    final vehicleController = TextEditingController(text: user.vehicleModel);
    final plateController = TextEditingController(text: user.vehiclePlateNumber);
    final bloodController = TextEditingController(text: user.bloodGroup);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Edit Rider Credentials', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Rider Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Vehicle Model'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Plate Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bloodController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Blood Group'),
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
              text: 'Save Changes',
              height: 42,
              onPressed: () {
                stateProvider.updateUserProfile(
                  user.copyWith(
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    vehicleModel: vehicleController.text.trim(),
                    vehiclePlateNumber: plateController.text.trim(),
                    bloodGroup: bloodController.text.trim(),
                  ),
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rider profile updated.'),
                    backgroundColor: AppColors.backgroundCardLight,
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
    final user = stateProvider.userProfile;
    final helmet = stateProvider.helmetState;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Rider & System Profile',
        subtitle: 'ID: ${user.id}',
        showBackButton: false,
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rider ID Card
              GlowContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cyanAccent, width: 2),
                            gradient: AppColors.heroGradient,
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: AppColors.cyanAccent, size: 36),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.fullName,
                                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const StatusBadge(label: 'VERIFIED', type: BadgeType.safe, showDot: false),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.phone,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ProfileInfo(
                          label: 'VEHICLE',
                          value: user.vehicleModel,
                          sub: user.vehiclePlateNumber,
                        ),
                        _ProfileInfo(
                          label: 'BLOOD GROUP',
                          value: user.bloodGroup,
                          sub: 'Trauma ID',
                          valueColor: AppColors.statusEmergency,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: AppColors.cyanAccent),
                          onPressed: () => _showEditProfileDialog(context),
                          tooltip: 'Edit Profile',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Connected Hardware Snapshot
              const Text(
                'PAIRED IOT HARDWARE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (helmet.isConnected ? AppColors.statusSafe : AppColors.statusOffline).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.sports_motorsports,
                        color: helmet.isConnected ? AppColors.statusSafe : AppColors.statusOffline,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            helmet.deviceName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MAC: ${helmet.macAddress} • ${helmet.firmwareVersion}',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DeviceConnectionScreen(stateProvider: stateProvider)),
                        );
                      },
                      child: const Text('MANAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyanAccent)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Quick Module Navigation List
              const Text(
                'SYSTEM HUBS & CONFIGURATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              _MenuTile(
                title: 'Safety Interlock & Checklist',
                subtitle: 'Helmet IR buckle and alcohol lockout inspection',
                icon: Icons.security,
                color: AppColors.statusSafe,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HelmetSafetyScreen(stateProvider: stateProvider)),
                  );
                },
              ),
              const SizedBox(height: 10),

              _MenuTile(
                title: 'Emergency Contact Configuration',
                subtitle: 'Manage rescue recipients & automated SMS numbers',
                icon: Icons.contact_emergency,
                color: AppColors.cyanAccent,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EmergencyContactConfigScreen(stateProvider: stateProvider)),
                  );
                },
              ),
              const SizedBox(height: 10),

              _MenuTile(
                title: 'Emergency SOS Command Center',
                subtitle: 'Manage rescue contacts and automated alerts',
                icon: Icons.emergency,
                color: AppColors.statusEmergency,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EmergencySosScreen(stateProvider: stateProvider)),
                  );
                },
              ),
              const SizedBox(height: 10),

              _MenuTile(
                title: 'System Settings & Calibration',
                subtitle: 'Configure thresholds, countdown timer, and sound',
                icon: Icons.settings,
                color: AppColors.cyanAccent,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SettingsScreen(stateProvider: stateProvider)),
                  );
                },
              ),
              const SizedBox(height: 10),

              _MenuTile(
                title: 'About Smart Helmet 2.0 Project',
                subtitle: 'Academic Innovation Exhibition 2026 specs',
                icon: Icons.school_outlined,
                color: AppColors.blueLight,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AboutProjectScreen(stateProvider: stateProvider)),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Logout / Exit Button
              CustomButton(
                text: 'LOG OUT / SWITCH RIDER',
                variant: ButtonVariant.outline,
                icon: Icons.logout_rounded,
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? valueColor;

  const _ProfileInfo({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white),
        ),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
