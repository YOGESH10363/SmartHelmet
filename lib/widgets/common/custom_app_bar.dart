import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/helmet_state.dart';
import 'status_badge.dart';

/// CustomAppBar provides consistent telemetry headers and Bluetooth status.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final HelmetState? helmetState;
  final VoidCallback? onSosPressed;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.helmetState,
    this.onSosPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (showBackButton && Navigator.of(context).canPop()) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (helmetState != null) ...[
                StatusBadge(
                  label: helmetState!.isConnected ? 'ESP32 ON' : 'OFFLINE',
                  type: helmetState!.isConnected ? BadgeType.safe : BadgeType.offline,
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(
                      helmetState!.batteryLevel > 20 ? Icons.battery_charging_full : Icons.battery_alert,
                      size: 18,
                      color: helmetState!.batteryLevel > 20 ? AppColors.statusSafe : AppColors.statusEmergency,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${helmetState!.batteryLevel}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              ...?actions,
              if (onSosPressed != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.emergency, color: AppColors.statusEmergency),
                  onPressed: onSosPressed,
                  tooltip: 'Manual Emergency SOS',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
