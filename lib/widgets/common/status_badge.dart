import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

enum BadgeType { safe, warning, emergency, offline, info }

/// StatusBadge renders colored status indicator badges with glowing dots.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color glow;

    switch (type) {
      case BadgeType.safe:
        color = AppColors.statusSafe;
        glow = AppColors.statusSafeGlow;
        break;
      case BadgeType.warning:
        color = AppColors.statusWarning;
        glow = AppColors.statusWarningGlow;
        break;
      case BadgeType.emergency:
        color = AppColors.statusEmergency;
        glow = AppColors.statusEmergencyGlow;
        break;
      case BadgeType.offline:
        color = AppColors.statusOffline;
        glow = Colors.black26;
        break;
      case BadgeType.info:
        color = AppColors.cyanAccent;
        glow = AppColors.cyanGlow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: 4, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTextStyles.badgeText.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
