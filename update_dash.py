import re

def update_dashboard():
    path = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update imports
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_shadows.dart';
import 'package:snooker_club/core/widgets/cards/info_card.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
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
"""
    # Replace top imports
    content = re.sub(r"import 'package:flutter/material.dart';.*?url_launcher/url_launcher.dart';", imports, content, flags=re.DOTALL)

    # 2. Re-write the DashboardScreen class definition and build method up to the Body
    old_build = """class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final timeStr = DateFormat('h:mm a').format(now);
    
    // In Phase 4, we use placeholder employee data
    const employeeName = 'Admin User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snooker Club'),
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
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            color: theme.colorScheme.onSurface,
            tooltip: 'Menu',
            onPressed: () {
              context.push(RouteNames.more);
            },
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
                  Text(
                    employeeName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Column(
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
                  ),
                ],
              ),
              const Gap(16),"""
              
    new_build = """class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    
    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    final employeeName = currentStaff?.name ?? 'Admin User';
    
    // Watch real time clock
    final now = ref.watch(realTimeClockProvider).value ?? DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

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
        title: const Text('Snooker Club'),
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
                  Column(
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
                  ),
                ],
              ),
              const Gap(16),"""
              
    content = content.replace(old_build, new_build)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_dashboard()
