import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/presentation/screens/staff_attendance_screen.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu'), centerTitle: false),
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
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        radius: 28,
                        child: Text(
                          staff.name.isNotEmpty
                              ? staff.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Role: ${staff.role.name.toUpperCase()}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (staff.role != StaffRole.owner) ...[
                                  const Gap(8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: staff.isLimitedAccess
                                          ? AppColors.warning.withValues(alpha: 0.15)
                                          : Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: staff.isLimitedAccess
                                            ? AppColors.warning.withValues(alpha: 0.4)
                                            : Colors.green.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      staff.accessLevel.displayName.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: staff.isLimitedAccess ? AppColors.warning : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!staff.isActive)
                              Text(
                                'Account Disabled',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Text(
              'CLUB OPERATIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.calendar_month,
              title: 'My Attendance',
              subtitle: 'Check-in history & working hours',
              iconColor: AppColors.primary,
              onTap: () {
                final staff = ref.read(currentStaffProvider).value;
                if (staff != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffAttendanceScreen(staffMember: staff),
                    ),
                  );
                }
              },
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.inventory_2,
              title: 'Inventory',
              subtitle: 'Stock & products',
              iconColor: AppColors.primary,
              onTap: () => context.push(RouteNames.inventory),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.credit_card,
              title: 'Credit',
              subtitle: 'Customer tabs',
              iconColor: AppColors.creditStatus,
              onTap: () => context.push(RouteNames.credit),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.people,
              title: 'Players',
              subtitle: 'Manage players & merge',
              iconColor: AppColors.secondary,
              onTap: () => context.push(RouteNames.players),
            ),
            const Gap(32),

            Text(
              'REPORTS & INSIGHTS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.analytics,
              title: 'Analytics',
              subtitle: 'Business insights',
              iconColor: AppColors.running,
              onTap: () => context.push(RouteNames.analytics),
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.assessment,
              title: 'Reports',
              subtitle: 'Daily summaries',
              iconColor: AppColors.success,
              onTap: () => context.push(RouteNames.reports),
            ),
            const Gap(32),

            Text(
              'TEAM & ADMINISTRATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),

            _MoreMenuItem(
              icon: Icons.group,
              title: 'Team Management',
              subtitle: 'Staff accounts and permissions',
              iconColor: Colors.blue,
              onTap: () => context.push(RouteNames.team),
            ),
            const Gap(12),

            _MoreMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences and configuration',
              iconColor: Colors.grey,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
