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

import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart';

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
  bool _isSwitchingClub = true;

  @override
  void initState() {
    super.initState();
    
    // Artificial delay to let Firebase fully sync and prevent synchronous cache emission exceptions
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSwitchingClub = false;
        });
      }
    });

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
    if (_isSwitchingClub) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.table_restaurant_outlined,
                  activeIcon: Icons.table_restaurant,
                  label: 'Game Activity',
                  isActive: currentIndex == 0,
                  onTap: () => _onItemTapped(0),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.flash_on_outlined,
                  activeIcon: Icons.flash_on,
                  label: 'Quick Sale',
                  isActive: currentIndex == 1,
                  onTap: () => _onItemTapped(1),
                  theme: theme,
                  isQuickSale: true,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'History',
                  isActive: currentIndex == 2,
                  onTap: () => _onItemTapped(2),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Overview',
                  isActive: currentIndex == 3,
                  onTap: () => _onItemTapped(3),
                  theme: theme,
                ),
              ],
            ),
          ),
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
    bool isQuickSale = false,
  }) {
    const brassGold = Color(0xFFC89B3C);
    const cream = Color(0xFFF6F1E4);
    const snookerRed = Color(0xFFC0432B);
    final mutedText = theme.colorScheme.onSurfaceVariant;

    final iconColor = isActive 
        ? (isQuickSale ? snookerRed : brassGold) 
        : (isQuickSale ? snookerRed.withValues(alpha: 0.8) : mutedText);

    final textColor = isActive ? cream : mutedText;
    final bgColor = isActive 
        ? (isQuickSale ? snookerRed.withValues(alpha: 0.15) : brassGold.withValues(alpha: 0.15)) 
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: iconColor, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
