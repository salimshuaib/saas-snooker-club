import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';

import 'package:snooker_club/core/models/currency.dart';

class TableRankingList extends StatelessWidget {
  final List<TablePerformanceItem> tables;
  final Currency currency;

  const TableRankingList({super.key, required this.tables, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) return const SizedBox.shrink();
    final maxRevenue = tables.first.totalBilled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Table Rankings', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: tables.asMap().entries.map((e) {
              final index = e.key;
              final table = e.value;
              final String medal = index == 0 ? '🥇' : (index == 1 ? '🥈' : (index == 2 ? '🥉' : ''));
              final double fraction = maxRevenue > 0 ? table.totalBilled / maxRevenue : 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text(medal.isNotEmpty ? medal : '#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(table.tableName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyHelper.formatWhole(table.totalBilled, currency),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
