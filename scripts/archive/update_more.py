import os

def rewrite_more():
    content = """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/widgets/dialogs/logout_dialog.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: theme.colorScheme.error,
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await LogoutDialog.show(context);
              if (confirmed == true && context.mounted) {
                try {
                  await ref.read(authRepositoryProvider).signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile Header
            Consumer(
              builder: (context, ref, _) {
                final staff = ref.watch(currentStaffProvider).value;
                if (staff == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Role: ${staff.role.name.toUpperCase()}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                            ),
                            if (!staff.isActive)
                              Text(
                                'Account Disabled',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),

            _MoreMenuItem(
              icon: Icons.sports_esports,
              title: 'All Games',
              subtitle: 'View all tables and active games',
              iconColor: Colors.purple,
              onTap: () => context.push(RouteNames.games),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.inventory_2,
              title: 'Inventory',
              subtitle: 'Manage products and stock',
              iconColor: Colors.orange,
              onTap: () => context.push(RouteNames.inventory),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.point_of_sale,
              title: 'Quick Sales',
              subtitle: 'Record over-the-counter sales',
              iconColor: AppColors.primary,
              onTap: () => context.push(RouteNames.quickSales),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.account_balance_wallet,
              title: 'Customer Credit',
              subtitle: 'Manage outstanding balances',
              iconColor: AppColors.error,
              onTap: () => context.push(RouteNames.credit),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.analytics,
              title: 'Analytics & Reports',
              subtitle: 'View detailed club performance',
              iconColor: AppColors.success,
              onTap: () => context.push(RouteNames.analytics),
            ),
            Consumer(
              builder: (context, ref, _) {
                final perms = ref.watch(currentStaffPermissionsProvider);
                if (!perms.canManageTeam) return const SizedBox.shrink();
                return Column(
                  children: [
                    const Gap(12),
                    _MoreMenuItem(
                      icon: Icons.people,
                      title: 'Team Management',
                      subtitle: 'Staff accounts and permissions',
                      iconColor: Colors.blue,
                      onTap: () => context.push(RouteNames.team),
                    ),
                  ],
                );
              }
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences and configuration',
              iconColor: AppColors.completed,
              onTap: () => context.push(RouteNames.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
"""
    with open('lib/features/dashboard/presentation/screens/more_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    rewrite_more()
