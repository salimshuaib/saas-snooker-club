import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/modals/app_modal.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/presentation/widgets/staff_form_dialog.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamMembersStreamProvider);
    final perms = ref.watch(currentStaffPermissionsProvider);

    // Only authorized users should access
    if (!perms.canManageTeam) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: const Center(child: Text('Unauthorized')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Team Management')),
      body: teamAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No team members found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, index) {
              final member = members[index];
              return _TeamMemberCard(member: member, allMembers: members);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppModal.showDialog(
            context: context,
            builder: (_) => const StaffFormDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
    );
  }
}

class _TeamMemberCard extends ConsumerWidget {
  final StaffMember member;
  final List<StaffMember> allMembers;

  const _TeamMemberCard({required this.member, required this.allMembers});

  bool _isLastActiveOwner() {
    if (member.role != StaffRole.owner) return false;
    if (!member.isActive) return false;
    final otherActiveOwners = allMembers
        .where(
          (m) => m.id != member.id && m.role == StaffRole.owner && m.isActive,
        )
        .toList();
    return otherActiveOwners.isEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUid = ref.watch(currentStaffProvider).value?.id;
    final isSelf = currentUid == member.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name + (isSelf ? ' (You)' : ''),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        member.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: member.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member.isActive ? 'Active' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: member.isActive
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  member.role.name.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        if (_isLastActiveOwner()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cannot edit the last active Owner. Create another Owner first.',
                              ),
                            ),
                          );
                          return;
                        }
                        AppModal.showDialog(
                          context: context,
                          builder: (_) =>
                              StaffFormDialog(existingMember: member),
                        );
                      },
                    ),
                    if (!isSelf)
                      TextButton.icon(
                        icon: Icon(
                          member.isActive ? Icons.block : Icons.check_circle,
                          size: 18,
                        ),
                        label: Text(member.isActive ? 'Disable' : 'Enable'),
                        style: TextButton.styleFrom(
                          foregroundColor: member.isActive
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        onPressed: () async {
                          if (member.isActive && _isLastActiveOwner()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cannot disable the last active Owner. Create another Owner first.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          final repo = ref.read(teamRepositoryProvider);
                          if (member.isActive) {
                            await repo.disableStaffMember(member.id);
                          } else {
                            await repo.enableStaffMember(member.id);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
