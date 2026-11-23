import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';
import 'welcome_screen.dart';

/// Screen 1: Splash Screen with Smart Helmet 2.0 branding and self-test loading.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  String _statusText = 'Initializing IoT Subsystems...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    // Staged startup sequence for high-tech commercial feel
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _statusText = 'Checking ESP32 Bluetooth Protocol...');
    });
    Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _statusText = 'Calibrating MPU6050 & MQ-3 Sensors...');
    });
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _statusText = 'System Ready.');
    });

    Timer(const Duration(milliseconds: 2900), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Glowing Brand Emblem
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.heroGradient,
                            border: Border.all(color: AppColors.cyanAccent, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cyanGlow,
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.sports_motorsports_rounded,
                              size: 64,
                              color: AppColors.cyanAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Title & Version
                        const Text(
                          AppConstants.appName,
                          style: AppTextStyles.displayLarge,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cyanAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cyanAccent.withOpacity(0.3)),
                          ),
                          child: const Text(
                            AppConstants.projectTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyanAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Progress indicator and technical state
                        SizedBox(
                          width: 160,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: AppColors.backgroundCardLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyanAccent),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          AppConstants.exhibitionName,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
