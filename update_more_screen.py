import re

def modify_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    import_stmt = "import 'package:snooker_club/features/team/providers/team_providers.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\n"
    if "features/team" not in content:
        last_import_idx = content.rfind("import ")
        end_of_last_import = content.find("\n", last_import_idx) + 1
        content = content[:end_of_last_import] + import_stmt + content[end_of_last_import:]

    if "class MoreScreen extends StatelessWidget" in content:
        content = content.replace("class MoreScreen extends StatelessWidget", "class MoreScreen extends ConsumerWidget")
    
    if "Widget build(BuildContext context) {" in content:
        content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")

    # Add the header and the team menu item
    body_target = """        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'Management & Settings',"""
              
    body_replacement = """        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile Header
            Consumer(
              builder: (context, ref, _) {
                final staff = ref.watch(currentStaffProvider).valueOrNull;
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
                        radius: 24,
                        child: Text(
                          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(staff.role.name.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: staff.isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: staff.isActive ? AppColors.success : AppColors.error),
                            const Gap(4),
                            Text(staff.isActive ? 'Active' : 'Disabled', style: TextStyle(fontSize: 12, color: staff.isActive ? AppColors.success : AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Gap(8),
            Text(
              'Management & Settings',"""
    
    if "Profile Header" not in content:
        content = content.replace(body_target, body_replacement)

    # Add Team Management if owner/manager
    menu_target = """            const Gap(12),
            _MoreMenuItem(
              icon: Icons.settings,"""
              
    menu_replacement = """            Consumer(
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
                      onTap: () => context.push('/team'),
                    ),
                  ],
                );
              }
            ),
            const Gap(12),
            _MoreMenuItem(
              icon: Icons.settings,"""
              
    if "Team Management" not in content:
        content = content.replace(menu_target, menu_replacement)
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_file('lib/features/dashboard/presentation/screens/more_screen.dart')
    print("Done")
