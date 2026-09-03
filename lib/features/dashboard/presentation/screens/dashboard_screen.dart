import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_activity_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    final employeeName = currentStaff?.name ?? 'Admin User';

    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final clubAsync = ref.watch(clubProfileProvider);
    
    // Tables & Active Games
    final tables = ref.watch(resolvedTablesProvider);
    
    // Group tables dynamically
    final groupedTables = <String, List<TableModel>>{
      'Snooker': [],
      'Pool': [],
      'Console & PC': [],
    };
    
    for (final table in tables) {
      if (table.type == TableType.snooker) {
        groupedTables['Snooker']!.add(table);
      } else if (table.type == TableType.indianPool || table.type == TableType.americanPool) {
        groupedTables['Pool']!.add(table);
      } else {
        groupedTables['Console & PC']!.add(table);
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: theme.colorScheme.onSurface,
          tooltip: 'Menu',
          onPressed: () {
            context.push(RouteNames.more);
          },
        ),
        title: Text(clubAsync.value?.clubName ?? 'Game Activity'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                employeeName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game Activity',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                '${tables.length} resources available • ${tables.where((t) => t.status != TableStatus.available).length} games running',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(24),
              
              ...groupedTables.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Gap(12),
                    ...entry.value.map((table) {
                      return Consumer(
                        builder: (context, ref, _) {
                          final activeGameAsync = ref.watch(activeGameProvider(table.id));
                          return GameActivityCard(
                            table: table,
                            activeGame: activeGameAsync.value,
                          );
                        },
                      );
                    }),
                    const Gap(24),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}