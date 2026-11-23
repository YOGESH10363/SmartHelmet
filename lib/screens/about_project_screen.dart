import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/glow_container.dart';

/// Screen 13: About Project Screen for Academic Innovation Exhibition presentation.
class AboutProjectScreen extends StatelessWidget {
  final AppStateProvider stateProvider;

  const AboutProjectScreen({super.key, required this.stateProvider});

  @override
  Widget build(BuildContext context) {
    final helmet = stateProvider.helmetState;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'About Smart Helmet 2.0',
        subtitle: 'Academic Innovation Exhibition 2026',
        helmetState: helmet,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Hero Banner
              GlowContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.heroGradient,
                        border: Border.all(color: AppColors.cyanAccent, width: 2),
                      ),
                      child: const Icon(Icons.sports_motorsports_rounded, size: 40, color: AppColors.cyanAccent),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      AppConstants.appName,
                      style: AppTextStyles.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppConstants.projectTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Text(
                        AppConstants.exhibitionName,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Executive Abstract
              const Text(
                'PROJECT ABSTRACT & INNOVATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Two-wheeler accidents constitute over 44% of road fatalities globally, predominantly caused by lack of protective headgear, driving under the influence (DUI), and delayed trauma care. \n\nSmart Helmet 2.0 provides an end-to-end IoT safety ecosystem combining proactive prevention (mandatory helmet wearing verification & breath alcohol ignition cut-off) with reactive trauma response (6-axis MPU6050 collision detection and autonomous GPS distress dispatch within 10 seconds).',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                ),
              ),

              const SizedBox(height: 22),

              // System Architecture Block Diagram
              const Text(
                'SYSTEM ARCHITECTURE & HARDWARE STACK',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: AppConstants.hardwareSpecs.map((spec) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.memory, size: 16, color: AppColors.cyanAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              spec,
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 22),

              // Team & Academic Supervision
              const Text(
                'PROJECT TEAM & MENTORSHIP',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyanAccent, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              GlowContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Project Lead & Architecture:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    const Text('Yogesh Sharma (Lead IoT & Flutter Developer)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    const Text('Academic Supervisor:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    const Text(AppConstants.teamSupervisor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cyanAccent)),
                    const SizedBox(height: 12),
                    const Text('Institution:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    const Text(AppConstants.collegeName, style: TextStyle(fontSize: 13, color: Colors.white)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    Text(
                      'Smart Helmet 2.0 ${AppConstants.appVersion}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Designed for Academic Innovation Exhibition 2026',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
