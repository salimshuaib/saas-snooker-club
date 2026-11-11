import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

void main() {
  group('StaffAccessLevel & StaffMember Model Tests', () {
    test('Default accessLevel is full for newly created StaffMember', () {
      final staff = StaffMember(
        id: 'user_1',
        name: 'John Doe',
        email: 'john@snooker.club',
        role: StaffRole.staff,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(staff.accessLevel, equals(StaffAccessLevel.full));
      expect(staff.isLimitedAccess, isFalse);
      expect(staff.hasFullAccess, isTrue);
      expect(staff.canViewFinancials, isTrue);
      expect(staff.canExportReports, isTrue);
    });

    test('Staff with Limited Access has restricted flags', () {
      final staff = StaffMember(
        id: 'user_2',
        name: 'Jane Staff',
        email: 'jane@snooker.club',
        role: StaffRole.staff,
        accessLevel: StaffAccessLevel.limited,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(staff.accessLevel, equals(StaffAccessLevel.limited));
      expect(staff.isLimitedAccess, isTrue);
      expect(staff.hasFullAccess, isFalse);
      expect(staff.canViewFinancials, isFalse);
      expect(staff.canExportReports, isFalse);
    });

    test('Manager with Limited Access has restricted flags', () {
      final manager = StaffMember(
        id: 'user_3',
        name: 'Bob Manager',
        email: 'bob@snooker.club',
        role: StaffRole.manager,
        accessLevel: StaffAccessLevel.limited,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(manager.isLimitedAccess, isTrue);
      expect(manager.canViewFinancials, isFalse);
      expect(manager.canExportReports, isFalse);
    });

    test('Owner is never limited even if accessLevel is set to limited', () {
      final owner = StaffMember(
        id: 'owner_1',
        name: 'Club Owner',
        email: 'owner@snooker.club',
        role: StaffRole.owner,
        accessLevel: StaffAccessLevel.limited,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Owner role always overrides
      expect(owner.isLimitedAccess, isFalse);
      expect(owner.canViewFinancials, isTrue);
      expect(owner.canExportReports, isTrue);
    });

    test('Serialization toMap and fromMap roundtrip preserves accessLevel', () {
      final original = StaffMember(
        id: 'user_4',
        name: 'Alice',
        email: 'alice@club.com',
        role: StaffRole.staff,
        accessLevel: StaffAccessLevel.limited,
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final map = original.toMap();
      expect(map['accessLevel'], equals('limited'));

      final fromMap = StaffMember.fromMap(map, 'user_4');
      expect(fromMap.accessLevel, equals(StaffAccessLevel.limited));
      expect(fromMap.isLimitedAccess, isTrue);
    });

    test('Legacy record without accessLevel defaults to full access', () {
      final legacyMap = <String, dynamic>{
        'name': 'Old Staff',
        'email': 'old@club.com',
        'role': 'staff',
        'isActive': true,
      };

      final member = StaffMember.fromMap(legacyMap, 'user_old');
      expect(member.accessLevel, equals(StaffAccessLevel.full));
      expect(member.isLimitedAccess, isFalse);
    });

    test('copyWith properly updates accessLevel', () {
      final original = StaffMember(
        id: 'user_5',
        name: 'Charlie',
        email: 'charlie@club.com',
        role: StaffRole.staff,
        accessLevel: StaffAccessLevel.full,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );

      final updated = original.copyWith(accessLevel: StaffAccessLevel.limited);
      expect(updated.accessLevel, equals(StaffAccessLevel.limited));
      expect(updated.isLimitedAccess, isTrue);
    });
  });

  group('StaffPermissions Tests', () {
    test('Limited Staff can clear credit but cannot view reports', () {
      final limitedStaff = StaffMember(
        id: 'staff_1',
        name: 'Limited Staff',
        email: 'staff@test.com',
        role: StaffRole.staff,
        accessLevel: StaffAccessLevel.limited,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final perms = StaffPermissions.fromStaff(limitedStaff);
      expect(perms.canClearCredit, isTrue); // Allowed to clear credit
      expect(perms.canViewReports, isFalse); // Blocked from reports
      expect(perms.canManageTeam, isFalse);
      expect(perms.canManageSettings, isFalse);
    });

    test('Full Staff can clear credit and view reports', () {
      final fullStaff = StaffMember(
        id: 'staff_2',
        name: 'Full Staff',
        email: 'staff2@test.com',
        role: StaffRole.staff,
        accessLevel: StaffAccessLevel.full,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final perms = StaffPermissions.fromStaff(fullStaff);
      expect(perms.canClearCredit, isTrue);
      expect(perms.canViewReports, isTrue);
    });

    test('Owner has full management permissions regardless', () {
      final owner = StaffMember(
        id: 'owner_1',
        name: 'Owner',
        email: 'owner@test.com',
        role: StaffRole.owner,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final perms = StaffPermissions.fromStaff(owner);
      expect(perms.canManageTeam, isTrue);
      expect(perms.canManageSettings, isTrue);
      expect(perms.canClearCredit, isTrue);
      expect(perms.canViewReports, isTrue);
      expect(perms.canDeleteRecords, isTrue);
    });
  });
}
