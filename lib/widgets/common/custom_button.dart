import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

enum ButtonVariant { primary, secondary, danger, outline }

/// CustomButton renders a technology-inspired high-contrast action button.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    List<BoxShadow> shadows = [];

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.cyanAccent;
        fg = Colors.black;
        border = Colors.transparent;
        shadows = [
          const BoxShadow(
            color: AppColors.cyanGlow,
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ];
        break;
      case ButtonVariant.secondary:
        bg = AppColors.backgroundCardLight;
        fg = Colors.white;
        border = AppColors.borderHighlight;
        break;
      case ButtonVariant.danger:
        bg = AppColors.statusEmergency;
        fg = Colors.white;
        border = Colors.transparent;
        shadows = [
          const BoxShadow(
            color: AppColors.statusEmergencyGlow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.cyanAccent;
        border = AppColors.cyanAccent;
        break;
    }

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 6),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.buttonText.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadows,
      ),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1.4),
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
