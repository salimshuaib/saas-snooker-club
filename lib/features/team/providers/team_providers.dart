import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';
import 'package:snooker_club/features/team/data/team_repository.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';

import 'package:snooker_club/core/providers/club_scope_provider.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return TeamRepository(clubId: clubId);
});

final teamMembersStreamProvider = StreamProvider<List<StaffMember>>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  if (repo.clubId == null) return Stream.value([]);
  return repo.watchTeamMembers();
});

/// Provides the currently logged-in staff member based on Firebase Auth UID.
final currentStaffProvider = StreamProvider<StaffMember?>((ref) async* {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  
  final repo = ref.watch(teamRepositoryProvider);
  
  if (repo.clubId == null) {
    yield null;
    return;
  }

  try {
    await for (final staff in repo.watchStaffMember(user.uid)) {
      if (staff == null) {
        // Auto-create legacy owner
        final newOwner = StaffMember(
          id: user.uid,
          name: 'Club Owner',
          email: user.email ?? '',
          role: StaffRole.owner,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.updateStaffMember(newOwner);
        yield newOwner;
      } else {
        yield staff;
      }
    }
  } catch (e, st) {
    print('Error in currentStaffProvider: $e\n$st');
    // Yield a fallback owner so the UI doesn't completely break while testing locally
    // IF permission is denied because rules aren't deployed yet.
    yield StaffMember(
      id: user.uid,
      name: 'Local Admin (Rules Not Deployed?)',
      email: user.email ?? '',
      role: StaffRole.owner,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
});

class StaffPermissions {
  final bool canManageTeam;
  final bool canManageSettings;
  final bool canDeleteRecords;
  final bool canClearCredit;
  final bool canViewReports;
  // Everyone active can do standard things like start/end games

  const StaffPermissions({
    required this.canManageTeam,
    required this.canManageSettings,
    required this.canDeleteRecords,
    required this.canClearCredit,
    required this.canViewReports,
  });

  factory StaffPermissions.fromRole(StaffRole? role) {
    if (role == null) {
      return const StaffPermissions(
        canManageTeam: false,
        canManageSettings: false,
        canDeleteRecords: false,
        canClearCredit: false,
        canViewReports: false,
      );
    }
    switch (role) {
      case StaffRole.owner:
        return const StaffPermissions(
          canManageTeam: true,
          canManageSettings: true,
          canDeleteRecords: true,
          canClearCredit: true,
          canViewReports: true,
        );
      case StaffRole.manager:
        return const StaffPermissions(
          canManageTeam: false,
          canManageSettings: false,
          canDeleteRecords: false, // Cannot permanently delete
          canClearCredit: true,    // Can manage/clear credits
          canViewReports: true,    // Can view reports
        );
      case StaffRole.staff:
        return const StaffPermissions(
          canManageTeam: false,
          canManageSettings: false,
          canDeleteRecords: false,
          canClearCredit: false,   // Cannot clear credits, only create
          canViewReports: false,   // Cannot view full business reports
        );
    }
  }
}

/// Helper provider to get current permissions synchronously
final currentStaffPermissionsProvider = Provider<StaffPermissions>((ref) {
  final currentStaff = ref.watch(currentStaffProvider).value;
  return StaffPermissions.fromRole(currentStaff?.role);
});
