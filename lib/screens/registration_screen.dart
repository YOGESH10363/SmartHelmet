import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/emergency_contact.dart';
import '../models/user_profile.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import 'main_navigation_shell.dart';

/// Screen 4: Registration Screen for enrolling rider profile and helmet device ID.
class RegistrationScreen extends StatefulWidget {
  final AppStateProvider? stateProvider;

  const RegistrationScreen({super.key, this.stateProvider});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Yogesh Sharma');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _vehicleController = TextEditingController(text: 'KTM Duke 390 / EV Smart');
  final _plateController = TextEditingController(text: 'MH 12 SH 2026');
  final _helmetIdController = TextEditingController(text: 'ESP32-SH2-2026-B3');
  final _bloodGroupController = TextEditingController(text: 'O+ Positive');
  final _emergencyNameController = TextEditingController(text: 'Primary Guardian');
  final _emergencyPhoneController = TextEditingController(text: '+91 98220 11223');

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    _helmetIdController.dispose();
    _bloodGroupController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (widget.stateProvider != null) {
      widget.stateProvider!.updateUserProfile(
        UserProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          vehicleModel: _vehicleController.text.trim(),
          vehiclePlateNumber: _plateController.text.trim(),
          bloodGroup: _bloodGroupController.text.trim(),
        ),
      );

      widget.stateProvider!.addEmergencyContact(
        EmergencyContact(
          id: 'contact-${DateTime.now().millisecondsSinceEpoch}',
          name: _emergencyNameController.text.trim(),
          phone: _emergencyPhoneController.text.trim(),
          relationship: 'Guardian',
          isPrimary: true,
        ),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Smart Helmet Registered & Paired Successfully!'),
        backgroundColor: AppColors.statusSafe,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const CustomAppBar(
        title: 'Helmet & Rider Enrollment',
        subtitle: 'Configure device telemetry & SOS',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Device & Rider Setup', style: AppTextStyles.displayMedium),
                const SizedBox(height: 6),
                const Text(
                  'Associate your physical ESP32 helmet with your vehicle and safety dispatch contacts.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Section 1: Rider Profile
                const Text(
                  '1. RIDER CREDENTIALS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 1.0),
                ),
                const SizedBox(height: 10),
                GlowContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person, color: AppColors.cyanAccent),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Icons.phone, color: AppColors.cyanAccent),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bloodGroupController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Blood Group (For Trauma Response)',
                          prefixIcon: Icon(Icons.bloodtype, color: AppColors.statusEmergency),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Vehicle & Helmet Hardware
                const Text(
                  '2. VEHICLE & ESP32 HARDWARE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 1.0),
                ),
                const SizedBox(height: 10),
                GlowContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _vehicleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Model / Make',
                          prefixIcon: Icon(Icons.two_wheeler, color: AppColors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _plateController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'License Registration Plate',
                          prefixIcon: Icon(Icons.badge, color: AppColors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _helmetIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Helmet ESP32 UUID / Device ID',
                          prefixIcon: Icon(Icons.memory, color: AppColors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Primary SOS Contact
                const Text(
                  '3. PRIMARY SOS DISPATCH CONTACT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.statusEmergency, letterSpacing: 1.0),
                ),
                const SizedBox(height: 10),
                GlowContainer(
                  padding: const EdgeInsets.all(18),
                  borderColor: AppColors.statusEmergency.withOpacity(0.3),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emergencyNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Contact Person Name',
                          prefixIcon: Icon(Icons.contact_emergency, color: AppColors.statusEmergency),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emergencyPhoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Emergency Phone Number (Auto SMS Recipient)',
                          prefixIcon: Icon(Icons.phone_in_talk, color: AppColors.statusEmergency),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required for SOS dispatch' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: 'REGISTER & PAIR HELMET',
                  variant: ButtonVariant.primary,
                  icon: Icons.check_circle_outline,
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
