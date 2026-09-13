import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_spacing.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';

class AnalyticsTimeFilterBar extends ConsumerWidget {
  const AnalyticsTimeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(analyticsTimeFilterProvider);
    final timeRange = ref.watch(analyticsTimeRangeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Dropdown / PopupMenu
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: PopupMenuButton<AnalyticsTimeFilter>(
              initialValue: selectedFilter,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedFilter.label,
                      style: AppTypography.textTheme.labelMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
              onSelected: (AnalyticsTimeFilter filter) async {
                if (filter == AnalyticsTimeFilter.custom) {
                  final customRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                    initialDateRange: DateTimeRange(
                      start: timeRange.start,
                      end: timeRange.end,
                    ),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: AppColors.primary,
                            brightness: isDark
                                ? Brightness.dark
                                : Brightness.light,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (customRange != null) {
                    ref
                        .read(analyticsCustomDateRangeProvider.notifier)
                        .setCustomRange(customRange);
                    ref
                        .read(analyticsTimeFilterProvider.notifier)
                        .setFilter(filter);
                  }
                } else {
                  ref
                      .read(analyticsTimeFilterProvider.notifier)
                      .setFilter(filter);
                }
              },
              itemBuilder: (context) {
                return AnalyticsTimeFilter.values.map((filter) {
                  return PopupMenuItem(
                    value: filter,
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        fontWeight: filter == selectedFilter
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: filter == selectedFilter
                            ? AppColors.primary
                            : null,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Active Range Display Badge
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${DateFormat('MMM d').format(timeRange.start)} - ${DateFormat('MMM d, yy').format(timeRange.end)}',
                      style: AppTypography.textTheme.bodySmall!.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
