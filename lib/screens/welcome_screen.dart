import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glow_container.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'main_navigation_shell.dart';

/// Screen 2: Welcome Onboarding Screen highlighting core IoT safety pillars.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _activePageIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.sports_motorsports_rounded,
      'title': 'Intelligent Helmet Interlock',
      'description': 'IR optical sensors verify helmet buckle before unlocking engine ignition. Zero riding without protective gear.',
      'tag': 'SAFETY COMPLIANCE',
      'color': AppColors.statusSafe,
    },
    {
      'icon': Icons.local_bar_rounded,
      'title': 'MQ-3 Alcohol Breathalyzer',
      'description': 'Real-time breath alcohol monitoring locks motorcycle ignition automatically if alcohol exceeds 200 PPM.',
      'tag': 'DUI PREVENTION',
      'color': AppColors.statusWarning,
    },
    {
      'icon': Icons.emergency_rounded,
      'title': 'Autonomous Crash & SOS Dispatch',
      'description': '6-axis MPU6050 accelerometer detects fall impact forces above 4.2 G, triggering automated GPS distress broadcasts.',
      'tag': 'CRITICAL RESCUE',
      'color': AppColors.statusEmergency,
    },
    {
      'icon': Icons.speed_rounded,
      'title': 'Commercial IoT Telemetry Cockpit',
      'description': 'Stream live speed, artificial horizon tilt, heading, satellite tracking, and battery health via Bluetooth Low Energy.',
      'tag': 'TELEMETRY HUD',
      'color': AppColors.cyanAccent,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cyanAccent.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.sports_motorsports, color: AppColors.cyanAccent, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                      );
                    },
                    child: const Text(
                      'Exhibition Demo',
                      style: TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Page View Feature Cards
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _activePageIndex = index),
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    final feature = _features[index];
                    final Color accentColor = feature['color'] as Color;

                    return GlowContainer(
                      borderColor: accentColor.withOpacity(0.35),
                      glowColor: accentColor.withOpacity(0.12),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accentColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              feature['tag'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                            ),
                            child: Icon(feature['icon'] as IconData, size: 40, color: accentColor),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            feature['title'] as String,
                            style: AppTextStyles.displayMedium.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            feature['description'] as String,
                            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_features.length, (index) {
                  final isActive = index == _activePageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.cyanAccent : AppColors.backgroundCardLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              CustomButton(
                text: 'LOGIN TO COCKPIT',
                variant: ButtonVariant.primary,
                icon: Icons.login_rounded,
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'PAIR & REGISTER HELMET',
                variant: ButtonVariant.outline,
                icon: Icons.bluetooth_searching,
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
