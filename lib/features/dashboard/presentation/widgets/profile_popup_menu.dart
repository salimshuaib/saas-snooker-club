import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/presentation/screens/staff_attendance_screen.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/floors/presentation/widgets/floor_selector_sheet.dart';
import 'package:snooker_club/core/widgets/modals/app_modal.dart';
import 'package:snooker_club/core/theme/app_colors.dart';

class ProfilePopupMenu extends ConsumerWidget {
  const ProfilePopupMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStaff = ref.watch(currentStaffProvider).value;
    final hasMultipleFloors = ref.watch(hasMultipleFloorsProvider);

    return PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 48),
      tooltip: 'Profile Options',
      icon: const CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.person, size: 16, color: Colors.white),
      ),
      onSelected: (value) async {
        if (value == 0) {
          // Check in/out
          if (currentStaff == null) return;
          final repo = ref.read(teamRepositoryProvider);
          if (currentStaff.isCheckedIn) {
            await repo.checkOutStaff(currentStaff.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checked out successfully. Alarms paused.')),
              );
            }
          } else {
            await repo.checkInStaff(currentStaff.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checked in successfully. You will now receive table alarms.')),
              );
            }
          }
        } else if (value == 1) {
          AppModal.showBottomSheet(
            context: context,
            builder: (_) => const FloorSelectorSheet(),
          );
        } else if (value == 2) {
          if (currentStaff == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StaffAttendanceScreen(staffMember: currentStaff),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        if (currentStaff != null)
          PopupMenuItem(
            value: 0,
            child: Row(
              children: [
                Icon(
                  currentStaff.isCheckedIn ? Icons.power_settings_new : Icons.check_circle,
                  color: currentStaff.isCheckedIn ? Colors.grey : Colors.green,
                ),
                const SizedBox(width: 12),
                Text(currentStaff.isCheckedIn ? 'Check Out' : 'Check In'),
              ],
            ),
          ),
        if (currentStaff != null)
          const PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.blue),
                SizedBox(width: 12),
                Text('My Attendance'),
              ],
            ),
          ),
        if (hasMultipleFloors)
          const PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.layers_outlined),
                SizedBox(width: 12),
                Text('Switch Floors'),
              ],
            ),
          ),
      ],
    );
  }
}
