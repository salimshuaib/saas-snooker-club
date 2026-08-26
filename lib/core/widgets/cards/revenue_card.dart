import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Revenue metric card with icon and optional trend indicator.
class RevenueCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color? color;
  final String? trend;
  final bool? isTrendPositive;

  const RevenueCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.color,
    this.trend,
    this.isTrendPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: accentColor),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isTrendPositive == true
                            ? Colors.green
                            : Colors.red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrendPositive == true
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color: isTrendPositive == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      const Gap(4),
                      Text(
                        trend!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isTrendPositive == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(16),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(4),
          Text(
            amount,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
