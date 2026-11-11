import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/desktop_dashboard_layout.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/presentation/widgets/pending_bills_icon_badge.dart';
import 'package:snooker_club/core/widgets/cards/info_card.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/core/widgets/modals/app_modal.dart';
import 'package:snooker_club/features/dashboard/presentation/widgets/profile_popup_menu.dart';
import 'package:snooker_club/features/announcements/presentation/widgets/announcements_sheet.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/inventory_status_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/features/expenses/providers/expense_providers.dart';
import 'package:snooker_club/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';
import 'package:snooker_club/features/team/presentation/screens/staff_attendance_screen.dart';
import 'package:snooker_club/features/team/providers/attendance_providers.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/available_tables_screen.dart';
import 'package:snooker_club/features/bookings/data/bookings_repository.dart';
import 'package:snooker_club/features/bookings/domain/models/booking_models.dart';
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

    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final clubAsync = ref.watch(clubProfileProvider);

    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    String employeeName = currentStaff?.name ?? 'Admin';
    if (currentStaff?.role == StaffRole.owner ||
        currentStaff == null ||
        employeeName == 'Admin' ||
        employeeName == 'Club Owner') {
      final oName = clubAsync.value?.ownerName;
      if (oName != null && oName.isNotEmpty) {
        employeeName = oName;
      }
    }

    final isDesktopTop = MediaQuery.sizeOf(context).width > 800;
    if (isDesktopTop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: const PendingBillsIconBadge(isFab: true),
      body: DesktopDashboardLayout(employeeName: employeeName),
      );
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                clubAsync.value?.clubName ?? AppLocalizations.of(context)!.appTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.assignment_outlined),
              tooltip: 'Notice Board',
              onPressed: () {
                AppModal.showBottomSheet(
                  context: context,
                  builder: (context) => const AnnouncementsSheet(),
                );
              },
            ),
          ],
        ),
        actions: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: ProfilePopupMenu())],
      ),
      floatingActionButton: const PendingBillsIconBadge(isFab: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            return SingleChildScrollView(
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
                  if (clubAsync.value?.clubName == 'Only We Have A Club' || clubAsync.value?.slug == 'cuezone')
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Wipe CueZone Data',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Wipe All Data?'),
                            content: const Text('This will permanently delete all games, tables data, players, and credit history for this club.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Yes, Wipe Data')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(gamesRepositoryProvider).wipeCueZoneData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wipe complete!'), backgroundColor: Colors.green));
                        }
                      },
                    ),
                ],
              ),
              const Gap(16),

              // Optional Update Banner
              Consumer(
                builder: (context, ref, child) {
                  final updateState = ref.watch(updateStateProvider);
                  if (!updateState.isOptionalUpdateAvailable)
                    return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
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
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Staff Shift & Check-In Status Card
              if (currentStaff != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentStaff.isCheckedIn
                          ? Colors.green.withValues(alpha: 0.4)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: currentStaff.isCheckedIn
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            child: Icon(
                              currentStaff.isCheckedIn ? Icons.check_circle : Icons.power_settings_new,
                              color: currentStaff.isCheckedIn ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        currentStaff.isCheckedIn ? 'Shift Active' : 'Currently Checked Out',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: currentStaff.isCheckedIn ? Colors.green : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (currentStaff.isLimitedAccess) ...[
                                      const Gap(6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'LIMITED',
                                          style: TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const Gap(2),
                                Text(
                                  currentStaff.isCheckedIn
                                      ? 'You are active & receiving table alarms'
                                      : 'Check in to start shift & receive alarms',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: const Text(
                                'Attendance',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StaffAttendanceScreen(staffMember: currentStaff),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: currentStaff.isCheckedIn
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.green.withValues(alpha: 0.15),
                                foregroundColor: currentStaff.isCheckedIn ? Colors.red : Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                currentStaff.isCheckedIn ? Icons.logout : Icons.login,
                                size: 16,
                              ),
                              label: Text(
                                currentStaff.isCheckedIn ? 'Check Out' : 'Check In',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () async {
                                final repo = ref.read(teamRepositoryProvider);
                                if (currentStaff.isCheckedIn) {
                                  await repo.checkOutStaff(currentStaff.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Checked out successfully. Alarms paused.')),
                                    );
                                  }
                                } else {
                                  await repo.checkInStaff(currentStaff.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Checked in successfully. You will now receive table alarms.')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

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
              Consumer(
                builder: (context, ref, child) {
                  final hasFloors = ref.watch(hasFloorsProvider);
                  final floors = ref.watch(floorsProvider).value ?? [];
                  if (!hasFloors || floors.length <= 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Overview', style: theme.textTheme.titleMedium),
                    );
                  }

                  final selectedFloorId = ref.watch(selectedFloorIdProvider);
                  final sortedFloors = List<FloorModel>.from(floors);
                  sortedFloors.sort((a, b) {
                    int getRank(FloorModel f) {
                      final n = f.name.toLowerCase();
                      if (n.contains('first') || n.contains('floor 1') || n.contains('1st') || n == '1') return 1;
                      if (n.contains('second') || n.contains('floor 2') || n.contains('2nd') || n == '2') return 2;
                      if (n.contains('third') || n.contains('floor 3') || n.contains('3rd') || n == '3') return 3;
                      if (n.contains('fourth') || n.contains('floor 4') || n.contains('4th') || n == '4') return 4;
                      return 10 + f.order;
                    }
                    final rankA = getRank(a);
                    final rankB = getRank(b);
                    if (rankA != rankB) return rankA.compareTo(rankB);
                    return a.name.compareTo(b.name);
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overview', style: theme.textTheme.titleMedium),
                      const Gap(10),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const Gap(8),
                            Text(
                              'Floor:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Gap(10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: (sortedFloors.any((f) => f.id == selectedFloorId) || selectedFloorId == null)
                                      ? selectedFloorId
                                      : sortedFloors.first.id,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  dropdownColor: theme.colorScheme.surface,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(
                                        'All Floors',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    ...sortedFloors.map(
                                      (floor) => DropdownMenuItem<String?>(
                                        value: floor.id,
                                        child: Text(
                                          floor.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (newFloorId) {
                                    ref
                                        .read(selectedFloorIdProvider.notifier)
                                        .selectFloor(newFloorId);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                    ],
                  );
                },
              ),

              // --- PHASE 5: NEW FINANCIAL SUMMARY ---
              const FinancialSummaryCard(),
              const Gap(12),
              if (currentStaff?.isLimitedAccess == true) ...[
                Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final myGamesCount = ref.watch(myStartedGamesCountProvider).value ?? 0;
                          return InfoCard(
                            title: 'Games by You',
                            value: '$myGamesCount',
                            icon: Icons.sports_esports_outlined,
                            iconColor: AppColors.primary,
                            onTap: () {
                              if (currentStaff != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StaffAttendanceScreen(staffMember: currentStaff),
                                  ),
                                );
                              }
                            },
                          );
                        },
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
                            iconColor: AppColors.success,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AvailableTablesScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final qsCount = ref.watch(
                          todaysQuickSalesCountProvider,
                        );
                        return InfoCard(
                          title: 'Quick Sales Today',
                          value: qsCount.toString(),
                          icon: Icons.shopping_cart_outlined,
                          iconColor: AppColors.tertiary,
                          onTap: () => context.push(RouteNames.quickSales),
                        );
                      },
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final inventoryAsync = ref.watch(
                          inventoryItemsProvider,
                        );
                        final selectedFloorId = ref.watch(selectedFloorIdProvider);
                        return InfoCard(
                          title: 'Inventory Alerts',
                          value: inventoryAsync.maybeWhen(
                            data: (items) {
                              final filteredItems = selectedFloorId != null
                                  ? items.where((i) => i.floorId == selectedFloorId).toList()
                                  : items;
                              final lowCount = filteredItems
                                  .where(
                                    (i) => i.isActive && i.currentStock <= 5,
                                  )
                                  .length;
                              return lowCount == 0
                                  ? 'All good'
                                  : '$lowCount items low';
                            },
                            orElse: () => '...',
                          ),
                          icon: Icons.warning_amber,
                          iconColor: AppColors.warning,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const InventoryStatusScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // Expenses Dashboard Card (Hidden for Limited Access)
              if (currentStaff?.isLimitedAccess != true) ...[
                Consumer(
                  builder: (context, ref, child) {
                    final currency = ref.watch(currencyProvider);
                    final todayExpenses = ref.watch(todaysExpensesTotalProvider).value ?? 0.0;
                    final pendingCreditCount = ref.watch(unsettledBusinessCreditCountProvider);

                    return InkWell(
                      onTap: () => context.push(RouteNames.expenses),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: pendingCreditCount > 0
                                ? AppColors.warning.withValues(alpha: 0.5)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.error.withValues(alpha: 0.12),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.error),
                            ),
                            const Gap(14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Today's Expenses",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (pendingCreditCount > 0) ...[
                                        const Gap(8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$pendingCreditCount Credit Due',
                                            style: const TextStyle(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const Gap(4),
                                  Text(
                                    CurrencyHelper.format(todayExpenses, currency),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: todayExpenses > 0 ? AppColors.error : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Add Expense',
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Gap(32),
              ],

              // Navigation Grid
              Text('Quick Access', style: theme.textTheme.titleMedium),
              const Gap(16),

              // --- NEW BOOKING CARD ---
              _BookingsDashboardCard(),

              const Gap(16),
              GridView.count(
                crossAxisCount: isDesktop ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _ModuleCard(
                    icon: Icons.inventory_2,
                    label: 'Inventory',
                    description: 'Stock & products',
                    color: AppColors.tertiary,
                    onTap: () => context.push(RouteNames.inventory),
                  ),
                  if (currentStaff?.isLimitedAccess != true) ...[
                    _ModuleCard(
                      icon: Icons.receipt_long,
                      label: 'Expenses',
                      description: 'Bills & purchases',
                      color: AppColors.error,
                      onTap: () => context.push(RouteNames.expenses),
                    ),
                    _ModuleCard(
                      icon: Icons.settings,
                      label: 'Settings',
                      description: 'App config',
                      color: AppColors.completed,
                      onTap: () => context.push(RouteNames.settings),
                    ),
                  ],
                ],
              ),
              const Gap(100),
            ],
          ),
        );
      },
    ),
      ),
    );
  }
}
class _BookingsDashboardCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final activeBookingsAsync = ref.watch(
      dateBookingsStreamProvider(DateTime(now.year, now.month, now.day)),
    ); 
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return InkWell(
      onTap: () => context.push(RouteNames.bookings),
      borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDesktop ? const Color(0xFF15191E) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
          border: Border.all(color: isDesktop ? const Color(0xFF3E4A56) : theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isDesktop ? 4 : 50),
              ),
              child: const Icon(Icons.calendar_month, color: AppColors.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservations & Bookings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDesktop ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  activeBookingsAsync.when(
                    data: (bookings) {
                      final unpaidCount = bookings.where((b) => b.status == BookingStatus.unconfirmed).length;
                      if (unpaidCount > 0) {
                        return Text(
                          '$unpaidCount UNCONFIRMED REQUESTS',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            letterSpacing: isDesktop ? 1.2 : null,
                          ),
                        );
                      }
                      return Text('Manage table reservations', style: theme.textTheme.bodySmall?.copyWith(color: isDesktop ? Colors.grey : null));
                    },
                    loading: () => Text('...', style: theme.textTheme.bodySmall),
                    error: (_, __) => Text('Error', style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
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
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDesktop ? const Color(0xFF1A2026) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
          border: Border.all(color: isDesktop ? const Color(0xFF2C353F) : theme.colorScheme.outlineVariant),
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
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(isDesktop ? 4 : 10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: isDesktop ? Colors.grey : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall?.copyWith(color: isDesktop ? Colors.white : null)),
                Text(
                  description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDesktop ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
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


