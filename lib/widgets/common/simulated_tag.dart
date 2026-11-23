import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// SimulatedTag displays a badge to clarify simulation status for exhibition reviewers.
class SimulatedTag extends StatelessWidget {
  final String label;

  const SimulatedTag({
    super.key,
    this.label = 'SIMULATED IOT STREAM',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cyanAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cyanAccent.withOpacity(0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hub_outlined, size: 12, color: AppColors.cyanAccent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.cyanAccent,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
