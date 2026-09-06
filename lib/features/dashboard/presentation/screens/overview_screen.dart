import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/detailed_overview_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/running_tables_screen.dart' as snooker_running;
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart' as snooker_qs;
import 'package:snooker_club/features/dashboard/presentation/screens/inventory_status_screen.dart' as snooker_inv;
import 'package:snooker_club/features/credit/presentation/screens/credit_screen.dart' as snooker_credit;
import 'package:snooker_club/features/bookings/data/bookings_repository.dart';
import 'package:snooker_club/features/bookings/domain/models/booking_models.dart' as snooker_booking_models;
import 'package:snooker_club/features/bookings/presentation/screens/booking_management_screen.dart' as snooker_bookings;

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final staffAsync = ref.watch(currentStaffProvider);
    final employeeName = staffAsync.value?.name ?? 'Admin';

    // Live counts for badges
    final runningCount = ref.watch(runningTablesCountProvider);
    final inventoryStats = ref.watch(inventoryStatsProvider);
    final lowStockCount = (inventoryStats['lowStockCount'] as int?) ?? 0;
    final outOfStockCount = (inventoryStats['outOfStockCount'] as int?) ?? 0;
    final alertCount = lowStockCount + outOfStockCount;

    return Scaffold(
      body: SafeArea(
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            // ── Welcome Header ──
            _WelcomeHeader(employeeName: employeeName),

            const Gap(24),

            // ── Financial Overview Card ──
            FinancialSummaryCard(
              onTapOverride: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DetailedOverviewScreen()),
                );
              },
            ),

            const Gap(28),

            // ── Bookings Overview ──
            const _BookingsDashboardCard(),

            const Gap(24),

            // ── Quick Actions Section ──
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 14),
              child: Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _OverviewMenuItem(
                  icon: Icons.sports_esports,
                  title: 'Games',
                  subtitle: 'Manage games',
                  iconColor: Colors.blue,
                  onTap: () => context.push(RouteNames.games),
                ),
                _OverviewMenuItem(
                  icon: Icons.warning_amber,
                  title: 'Inventory Alerts',
                  subtitle: 'Low stock warnings',
                  iconColor: Colors.red,
                  badgeCount: alertCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const snooker_inv.InventoryStatusScreen()),
                    );
                  },
                ),
                _OverviewMenuItem(
                  icon: Icons.flash_on,
                  title: 'Quick Sale',
                  subtitle: 'Food & beverage',
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const snooker_qs.NewQuickSaleScreen()),
                    );
                  },
                ),
                _OverviewMenuItem(
                  icon: Icons.table_restaurant,
                  title: 'Running Tables',
                  subtitle: 'View active games',
                  iconColor: Colors.blue,
                  badgeCount: runningCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const snooker_running.RunningTablesScreen()),
                    );
                  },
                ),
                _OverviewMenuItem(
                  icon: Icons.credit_score,
                  title: 'Credit Profiles',
                  subtitle: 'Player credit & ledger',
                  iconColor: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const snooker_credit.CreditScreen()),
                    );
                  },
                ),
                _OverviewMenuItem(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'Charts & insights',
                  iconColor: Colors.indigo,
                  onTap: () => context.push(RouteNames.analytics),
                ),
                _OverviewMenuItem(
                  icon: Icons.summarize,
                  title: 'Reports',
                  subtitle: 'Generate & export',
                  iconColor: Colors.teal.shade700,
                  onTap: () => context.push(RouteNames.reports),
                ),
              ],
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome Header ──────────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  final String employeeName;
  const _WelcomeHeader({required this.employeeName});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Menu Button
        IconButton(
          icon: const Icon(Icons.menu),
          color: theme.colorScheme.onSurface,
          tooltip: 'Menu',
          onPressed: () => context.push(RouteNames.more),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Gap(12),
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'A',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Gap(14),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                employeeName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Clock
        const _RealTimeClockWidget(),
      ],
    );
  }
}

// ─── Bookings Card ───────────────────────────────────────────────
class _BookingsDashboardCard extends ConsumerWidget {
  const _BookingsDashboardCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final activeBookingsAsync = ref.watch(dateBookingsStreamProvider(DateTime(now.year, now.month, now.day))); // Just getting today's bookings for the badge

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const snooker_bookings.BookingManagementScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month, color: AppColors.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Table Bookings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  activeBookingsAsync.when(
                    data: (bookings) {
                      final pendingCount = bookings.where((b) => b.status == snooker_booking_models.BookingStatus.pending).length;
                      if (pendingCount > 0) {
                        return Text('$pendingCount pending requests', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold));
                      }
                      return Text('Manage table reservations', style: theme.textTheme.bodySmall);
                    },
                    loading: () => Text('Manage table reservations', style: theme.textTheme.bodySmall),
                    error: (_, __) => Text('Manage table reservations', style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Grid Card (Module Card style) ───────────────────────────────
class _OverviewMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  final int badgeCount;

  const _OverviewMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 18,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Real-Time Clock ─────────────────────────────────────────────
class _RealTimeClockWidget extends StatelessWidget {
  const _RealTimeClockWidget();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final theme = Theme.of(context);
        final now = DateTime.now();
        final dateStr = DateFormat('EEE, MMM d').format(now);
        final timeStr = DateFormat('h:mm a').format(now);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeStr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              dateStr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
