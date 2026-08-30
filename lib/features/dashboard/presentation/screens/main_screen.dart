import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/start_game_sheet.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/providers/update_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _hasInitialized = false;

  void _triggerInitialization(String clubId) {
    if (_hasInitialized) return;
    _hasInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsRepositoryProvider).migrateTablesPricing();
      ref.read(inventorySeederProvider)();
    });
  }

  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual<String?>(clubIdProvider, (previous, next) {
        if (next != null) {
          _triggerInitialization(next);
        }
      }, fireImmediately: true));

      // Keep critical providers active at the root level to prevent 
      // Riverpod TickerMode crashes when switching GoRouter tabs or dialogs.
      // Using listenManual bypasses TickerMode pausing completely.
      _subscriptions.add(ref.listenManual(tablesProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(resolvedTablesProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(runningTablesCountProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(availableTablesCountProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(appSettingsProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(todaysGamesRevenueStreamProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(pendingCreditsProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(todaysQuickSalesCountProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(inventoryItemsProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(currentStaffProvider, (_, __) {}));
      _subscriptions.add(ref.listenManual(updateStateProvider, (_, __) {}));
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _showStartGameFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StartGameSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          onPressed: _showStartGameFlow,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: const Icon(Icons.add, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: theme.colorScheme.surface,
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              isActive: currentIndex == 0,
              onTap: () => _onItemTapped(0),
              theme: theme,
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: 'History',
              isActive: currentIndex == 1,
              onTap: () => _onItemTapped(1),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final color = isActive ? AppColors.primary : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 28),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
