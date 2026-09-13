import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';

class CRMSidebar extends ConsumerWidget {
  const CRMSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentPath = GoRouterState.of(context).uri.path;

    final club = ref.watch(clubProfileProvider).value;
    final clubName = club?.clubName ?? 'S&B Manager';

    final currentStaff = ref.watch(currentStaffProvider).value;
    final isOwnerOrAdmin = currentStaff?.role == StaffRole.owner || currentStaff?.role == StaffRole.manager;

    return Container(
      width: 250,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(Icons.sports_esports, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    clubName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SidebarItem(
                  icon: Icons.table_restaurant,
                  label: 'Live Tables',
                  isSelected: currentPath == RouteNames.live,
                  onTap: () => context.go(RouteNames.live),
                ),
                _SidebarItem(
                  icon: Icons.bar_chart,
                  label: 'Dashboard',
                  isSelected: currentPath == RouteNames.dashboard,
                  onTap: () => context.go(RouteNames.dashboard),
                ),
                _SidebarItem(
                  icon: Icons.menu_book,
                  label: 'Khata',
                  isSelected: currentPath.startsWith(RouteNames.khata),
                  onTap: () => context.go(RouteNames.khata),
                ),
                _SidebarItem(
                  icon: Icons.flash_on,
                  label: 'Quick Sale',
                  isSelected: currentPath == RouteNames.quickSales,
                  onTap: () => context.go(RouteNames.quickSales),
                ),
                _SidebarItem(
                  icon: Icons.receipt_long,
                  label: 'History',
                  isSelected: currentPath == RouteNames.history,
                  onTap: () => context.go(RouteNames.history),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text('MANAGEMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                _SidebarItem(
                  icon: Icons.people,
                  label: 'Players',
                  isSelected: currentPath.startsWith('${RouteNames.more}/players'),
                  onTap: () => context.push('${RouteNames.more}/players'),
                ),
                _SidebarItem(
                  icon: Icons.inventory_2,
                  label: 'Inventory',
                  isSelected: currentPath.startsWith(RouteNames.inventory),
                  onTap: () => context.push(RouteNames.inventory),
                ),
                _SidebarItem(
                  icon: Icons.auto_graph,
                  label: 'Reports',
                  isSelected: currentPath.startsWith('${RouteNames.more}/reports'),
                  onTap: () => context.push('${RouteNames.more}/reports'),
                ),
                if (isOwnerOrAdmin) ...[
                  _SidebarItem(
                    icon: Icons.badge,
                    label: 'Team',
                    isSelected: currentPath == RouteNames.team,
                    onTap: () => context.push(RouteNames.team),
                  ),
                  _SidebarItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    isSelected: currentPath.startsWith('${RouteNames.more}/settings'),
                    onTap: () => context.push('${RouteNames.more}/settings'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
