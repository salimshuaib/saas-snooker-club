import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/modals/app_modal.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/presentation/screens/staff_attendance_screen.dart';
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
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          title: const Text('Team Management'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: Colors.white38),
              Gap(12),
              Text(
                'Unauthorized Access',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              Gap(4),
              Text(
                'You do not have permission to manage team members.',
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Team Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: teamAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 54,
                    color: Colors.white24,
                  ),
                  Gap(12),
                  Text(
                    'No team members found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Gap(4),
                  Text(
                    'Tap "Add Staff" below to add your first member',
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            );
          }
          final activeCount = members.where((m) => m.isActive).length;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: members.length + 1,
            separatorBuilder: (_, _) => const Gap(12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${members.length} Staff Member${members.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '$activeCount Active',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                );
              }
              final member = members[index - 1];
              return _TeamMemberCard(member: member, allMembers: members);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            err.toString(),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          AppModal.showDialog(
            context: context,
            builder: (_) => const StaffFormDialog(),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Add Staff',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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

  (Color, IconData, String) _getRoleMeta(StaffRole role) {
    switch (role) {
      case StaffRole.owner:
        return (const Color(0xFFF59E0B), Icons.workspace_premium_rounded, 'OWNER');
      case StaffRole.manager:
        return (const Color(0xFF06B6D4), Icons.badge_rounded, 'MANAGER');
      case StaffRole.staff:
        return (const Color(0xFF818CF8), Icons.person_rounded, 'STAFF');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentStaffProvider).value?.id;
    final isSelf = currentUid == member.id;
    final (roleColor, roleIcon, roleLabel) = _getRoleMeta(member.role);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, Name & Email, Active/Disabled Status Badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
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
                            member.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelf) ...[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(2),
                    Text(
                      member.email,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: member.isActive
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: member.isActive
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.error.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: member.isActive
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      member.isActive ? 'Active' : 'Disabled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: member.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(12),

          // Row 2: Role Badge & Access Level Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 12, color: roleColor),
                    const Gap(4),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (member.role != StaffRole.owner) ...[
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (member.isLimitedAccess
                            ? AppColors.warning
                            : AppColors.success)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (member.isLimitedAccess
                              ? AppColors.warning
                              : AppColors.success)
                          .withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        member.isLimitedAccess
                            ? Icons.lock_outline_rounded
                            : Icons.verified_user_rounded,
                        size: 11,
                        color: member.isLimitedAccess
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      const Gap(4),
                      Text(
                        member.accessLevel.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: member.isLimitedAccess
                              ? AppColors.warning
                              : AppColors.success,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (member.isCheckedIn) ...[
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 11,
                        color: Colors.blueAccent,
                      ),
                      Gap(4),
                      Text(
                        'ON SHIFT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueAccent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const Gap(12),
          const Divider(color: Colors.white10, height: 1),
          const Gap(10),

          // Row 3: Action Buttons (Attendance, Edit, Disable/Enable)
          Row(
            children: [
              Expanded(
                child: _CardActionButton(
                  icon: Icons.calendar_month_rounded,
                  label: 'Attendance',
                  color: Colors.white70,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StaffAttendanceScreen(staffMember: member),
                      ),
                    );
                  },
                ),
              ),
              const Gap(8),
              Expanded(
                child: _CardActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: AppColors.primaryLight,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  onTap: () {
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
              ),
              if (!isSelf) ...[
                const Gap(8),
                Expanded(
                  child: _CardActionButton(
                    icon: member.isActive
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    label: member.isActive ? 'Disable' : 'Enable',
                    color: member.isActive ? AppColors.error : AppColors.success,
                    backgroundColor: (member.isActive
                            ? AppColors.error
                            : AppColors.success)
                        .withValues(alpha: 0.1),
                    onTap: () async {
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
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const Gap(5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
