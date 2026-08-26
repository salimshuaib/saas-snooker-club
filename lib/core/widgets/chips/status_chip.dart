import 'package:flutter/material.dart';
import 'package:snooker_club/core/theme/app_colors.dart';

/// Color-coded status indicator chip.
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool showDot;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.showDot = true,
  });

  /// Create from status string.
  factory StatusChip.fromStatus(String status) {
    return StatusChip(
      label: status,
      color: AppColors.getStatusColor(status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...
          [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
