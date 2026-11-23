import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import 'registration_screen.dart';
import 'main_navigation_shell.dart';

/// Screen 3: Rider Login Screen for authenticating helmet owner profile.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'yogesh.iot@smarthelmet.io');
  final _passwordController = TextEditingController(text: '••••••••');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

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
        title: 'Rider Authentication',
        subtitle: 'Connect to Smart Helmet profile',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TELEMETRY ACCESS PORTAL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.cyanAccent),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Sign In to Helmet', style: AppTextStyles.displayMedium),
                const SizedBox(height: 6),
                const Text(
                  'Access real-time safety interlock, collision telemetry, and emergency dispatch system.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Login form card
                GlowContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Rider ID or Email',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.cyanAccent),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter Rider ID' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Security PIN / Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.cyanAccent),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 4 ? 'PIN must be at least 4 digits' : null,
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: 'AUTHENTICATE & ENTER',
                        variant: ButtonVariant.primary,
                        icon: Icons.fingerprint,
                        width: double.infinity,
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Demo one-click access card
                GlowContainer(
                  padding: const EdgeInsets.all(16),
                  borderColor: AppColors.cyanAccent.withOpacity(0.3),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: AppColors.cyanAccent, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Exhibition Quick Access',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            Text(
                              'Pre-loaded with live ESP32 simulation telemetry.',
                              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.9), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _handleLogin,
                        child: const Text('ENTER', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cyanAccent)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have a registered helmet? ", style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                        );
                      },
                      child: const Text(
                        'Register Device',
                        style: TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
