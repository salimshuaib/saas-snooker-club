import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/table_card.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/screens/manual_game_setup_screen.dart';
import 'package:snooker_club/core/widgets/shared/date_navigation_header.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Seed default tables if first launch
      ref.read(gamesRepositoryProvider).seedTablesIfEmpty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final tables = ref.watch(resolvedTablesProvider);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isToday = selectedDate == todayDate;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(AppLocalizations.of(context)!.games),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Date Selector Header ──
          DateNavigationHeader(
            selectedDate: selectedDate,
            onDateChanged: (date) {
              ref.read(selectedDateProvider.notifier).setDate(date);
            },
          ),

          // ── Table Grid ──
          Expanded(
            child: tables.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildTableGrid(tables, selectedDate, isToday, theme),
          ),
        ],
      ),
      floatingActionButton: isToday
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
useRootNavigator: true,
context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: const Text('Record Ongoing Game'),
                          subtitle: const Text('Start a live timer backdated by elapsed time'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ManualGameSetupScreen(
                                  employeeId: 'admin_123',
                                  isCompletedGame: false,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Record Completed Game'),
                          subtitle: const Text('Generate a bill directly for a finished game'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ManualGameSetupScreen(
                                  employeeId: 'admin_123',
                                  isCompletedGame: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Manual Entry'),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }

  Widget _buildTableGrid(
    List<TableModel> tables,
    DateTime selectedDate,
    bool isToday,
    ThemeData theme,
  ) {
    final billiardsTables = tables.where((t) => !t.type.isOtherGame).toList();
    final otherGamesTables = tables.where((t) => t.type.isOtherGame).toList();

    if (otherGamesTables.isEmpty) {
      return _buildGridList(billiardsTables, selectedDate, isToday, theme);
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Tables'),
              Tab(text: 'Other Games'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _buildGridList(billiardsTables, selectedDate, isToday, theme),
                _buildGridList(otherGamesTables, selectedDate, isToday, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridList(
    List<TableModel> typeTables,
    DateTime selectedDate,
    bool isToday,
    ThemeData theme,
  ) {
    // Group tables by type
    final grouped = <TableType, List<TableModel>>{};
    for (final table in typeTables) {
      grouped.putIfAbsent(table.type, () => []).add(table);
    }

    if (grouped.isEmpty) {
      return const Center(child: Text("No tables available."));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              entry.key.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entry.value.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final table = entry.value[index];
              return TableCard(
                table: table,
                selectedDate: selectedDate,
                isToday: isToday,
              );
            },
          ),
          const Gap(16),
        ],
        const Gap(80),
      ],
    );
  }
}
