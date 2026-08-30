import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/loading/empty_state_widget.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class AvailableTablesScreen extends ConsumerWidget {
  const AvailableTablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(resolvedTablesProvider);
    final availableTables = tables.where((t) => t.status == TableStatus.available).toList();
    
    final billiardsTables = availableTables.where((t) => !t.type.isOtherGame).toList();
    final otherGamesTables = availableTables.where((t) => t.type.isOtherGame).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Available Tables'),
          centerTitle: false,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Tables'),
              Tab(text: 'Other Games'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(billiardsTables),
            _buildList(otherGamesTables),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<TableModel> tables) {
    if (tables.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.table_restaurant,
        title: 'No Available Tables',
        subtitle: 'All tables in this category are currently engaged or not created.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return _AvailableTableTile(table: table);
      },
    );
  }
}

class _AvailableTableTile extends StatelessWidget {
  final TableModel table;

  const _AvailableTableTile({required this.table});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.available.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push(
              '/games/table',
              extra: {
                'table': table,
                'selectedDate': DateTime.now(),
                'isToday': true,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.available.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.table_restaurant, color: AppColors.available, size: 26),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Gap(4),
                      Text(
                        'Assigned Game: \',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.available.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.available,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        'AVAILABLE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.available,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
