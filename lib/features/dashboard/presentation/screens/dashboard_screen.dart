import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/cards/info_card.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/running_tables_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/available_tables_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/inventory_status_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';
import 'package:snooker_club/core/providers/update_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Real-time clock provider
final realTimeClockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});


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
        title: Text(clubAsync.value?.clubName ?? AppLocalizations.of(context)!.appTitle),
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
              // Header
              Text(
                'Welcome Back,',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      employeeName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const _RealTimeClockWidget(),
                ],
              ),
              const Gap(16),

              // Optional Update Banner
              Consumer(
                builder: (context, ref, child) {
                  final updateState = ref.watch(updateStateProvider);
                  if (!updateState.isOptionalUpdateAvailable) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Available (${updateState.latestVersion})',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                updateState.updateMessage.isNotEmpty
                                    ? updateState.updateMessage
                                    : 'A new version of S&B Manager is ready to install.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final url = Uri.parse(updateState.updateUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewQuickSaleScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.flash_on),
                      label: const Text('New Quick Sale'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(24),

              // Quick Stats
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium,
                ),
                const Gap(12),
                
                // --- PHASE 5: NEW FINANCIAL SUMMARY ---
                const FinancialSummaryCard(),
                const Gap(12),

                // Table Status Grid
                Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final runningCount = ref.watch(runningTablesCountProvider);
                          return InfoCard(
                            title: 'Running Tables',
                            value: runningCount.toString(),
                            icon: Icons.table_restaurant,
                            iconColor: AppColors.running,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RunningTablesScreen(),
                                ),
                              );
                            },
                          );
                        }
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final availableCount = ref.watch(availableTablesCountProvider);
                          return InfoCard(
                            title: 'Available Tables',
                            value: availableCount.toString(),
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.available,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AvailableTablesScreen(),
                                ),
                              );
                            },
                          );
                        }
                      ),
                    ),
                  ],
                ),
                const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final qsCount = ref.watch(todaysQuickSalesCountProvider);
                        return InfoCard(
                          title: 'Quick Sales Today',
                          value: qsCount.toString(),
                          icon: Icons.shopping_cart_outlined,
                          iconColor: AppColors.tertiary,
                          onTap: () => context.push(RouteNames.quickSales),
                        );
                      }
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final inventoryAsync = ref.watch(inventoryItemsProvider);
                        return InfoCard(
                          title: 'Inventory Alerts',
                          value: inventoryAsync.maybeWhen(
                            data: (items) {
                              final lowCount = items.where((i) => i.isActive && i.currentStock <= 5).length;
                              return lowCount == 0 ? 'All good' : '$lowCount items low';
                            },
                            orElse: () => '...',
                          ),
                          icon: Icons.warning_amber,
                          iconColor: AppColors.warning,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InventoryStatusScreen(),
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ),
                ],
              ),
              const Gap(32),

              // Navigation Grid
              Text(
                'Quick Access',
                style: theme.textTheme.titleMedium,
              ),
              const Gap(16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _ModuleCard(
                    icon: Icons.sports_esports,
                    label: 'Games',
                    description: 'Manage tables & sessions',
                    color: AppColors.primary,
                    onTap: () => context.push(RouteNames.games),
                  ),
                  _ModuleCard(
                    icon: Icons.inventory_2,
                    label: 'Inventory',
                    description: 'Stock & products',
                    color: AppColors.tertiary,
                    onTap: () => context.push(RouteNames.inventory),
                  ),

                  _ModuleCard(
                    icon: Icons.analytics,
                    label: 'Analytics',
                    description: 'Business insights',
                    color: AppColors.running,
                    onTap: () => context.push(RouteNames.analytics),
                  ),
                  _ModuleCard(
                    icon: Icons.credit_card,
                    label: 'Credit',
                    description: 'Customer tabs',
                    color: AppColors.creditStatus,
                    onTap: () => context.push(RouteNames.credit),
                  ),
                  _ModuleCard(
                    icon: Icons.assessment,
                    label: 'Reports',
                    description: 'Daily summaries',
                    color: AppColors.success,
                    onTap: () => context.push(RouteNames.reports),
                  ),
                  _ModuleCard(
                    icon: Icons.settings,
                    label: 'Settings',
                    description: 'App config',
                    color: AppColors.completed,
                    onTap: () => context.push(RouteNames.settings),
                  ),
                ],
              ),
              const Gap(100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  description,
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





class _RealTimeClockWidget extends ConsumerWidget {
  const _RealTimeClockWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(realTimeClockProvider).value ?? DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          dateStr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          timeStr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}