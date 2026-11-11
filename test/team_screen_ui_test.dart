import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/presentation/screens/team_screen.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

void main() {
  testWidgets('TeamScreen renders modern cards with aligned action buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final members = [
      StaffMember(
        id: 'owner-1',
        name: 'Sunny Dehda',
        email: 'admin@test0.com',
        role: StaffRole.owner,
        accessLevel: StaffAccessLevel.full,
        createdAt: now,
        updatedAt: now,
      ),
      StaffMember(
        id: 'staff-2',
        name: 'Shemdi',
        email: 'lallu@gmail.com',
        role: StaffRole.staff,
        accessLevel: StaffAccessLevel.limited,
        createdAt: now,
        updatedAt: now,
      ),
      StaffMember(
        id: 'owner-3',
        name: 'Ravi',
        email: 'ravi@gmail.com',
        role: StaffRole.owner,
        accessLevel: StaffAccessLevel.full,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentStaffProvider.overrideWith((ref) => Stream.value(members.first)),
          teamMembersStreamProvider.overrideWith((ref) => Stream.value(members)),
        ],
        child: const MaterialApp(
          home: TeamScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Header summary
    expect(find.text('Team Management'), findsOneWidget);
    expect(find.text('3 Staff Members'), findsOneWidget);
    expect(find.text('3 Active'), findsOneWidget);

    // Verify Members
    expect(find.text('Sunny Dehda'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('Shemdi'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);

    // Verify Role Badges
    expect(find.text('OWNER'), findsNWidgets(2));
    expect(find.text('STAFF'), findsOneWidget);
    expect(find.text('LIMITED ACCESS'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Attendance'), findsNWidgets(3));
    expect(find.text('Edit'), findsNWidgets(3));
    // Self does not have disable button, so 2 disable buttons
    expect(find.text('Disable'), findsNWidgets(2));

    // Verify Add Staff FAB
    expect(find.text('Add Staff'), findsOneWidget);
  });
}
