import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

String staffAttendanceStatus(StaffMember staff, {DateTime? now}) {
  if (!staff.isCheckedIn) return 'Offline';

  final checkInTime = staff.lastCheckInTime;
  if (checkInTime == null) return 'Checked in';

  final elapsedMinutes = (now ?? DateTime.now())
      .difference(checkInTime)
      .inMinutes
      .clamp(0, 1 << 31);
  if (elapsedMinutes < 1) return 'Checked in just now';

  final hours = elapsedMinutes ~/ 60;
  final minutes = elapsedMinutes % 60;
  if (hours == 0) return 'Checked in ${minutes}m ago';
  if (minutes == 0) return 'Checked in ${hours}h ago';
  return 'Checked in ${hours}h ${minutes}m ago';
}

class StaffAttendanceAction extends ConsumerStatefulWidget {
  final StaffMember staff;
  final bool showStatus;

  const StaffAttendanceAction({
    super.key,
    required this.staff,
    this.showStatus = false,
  });

  @override
  ConsumerState<StaffAttendanceAction> createState() =>
      _StaffAttendanceActionState();
}

class _StaffAttendanceActionState extends ConsumerState<StaffAttendanceAction> {
  bool _isSaving = false;

  Future<void> _toggleAttendance() async {
    if (_isSaving) return;
    final wasCheckedIn = widget.staff.isCheckedIn;
    setState(() => _isSaving = true);

    try {
      final audioReady = wasCheckedIn
          ? true
          : await TableAlarmService().prepareFallbackAudio();
      final repository = ref.read(teamRepositoryProvider);
      if (wasCheckedIn) {
        await repository.checkOutStaff(widget.staff.id);
      } else {
        await repository.checkInStaff(widget.staff.id);
      }

      if (!mounted) return;
      final message = wasCheckedIn
          ? 'Checked out successfully. Alarms paused.'
          : audioReady
          ? 'Checked in successfully. You will now receive table alarms.'
          : 'Checked in, but this device could not enable alarm audio.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update attendance: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    final status = staffAttendanceStatus(staff);
    final isCheckedIn = staff.isCheckedIn;
    final theme = Theme.of(context);

    final action = Tooltip(
      message: '$status. Tap to ${isCheckedIn ? 'check out' : 'check in'}.',
      child: ActionChip(
        backgroundColor: isCheckedIn
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        side: BorderSide(
          color: isCheckedIn ? Colors.green : Colors.grey,
          width: 1,
        ),
        label: Text(isCheckedIn ? 'Check Out' : 'Check In'),
        avatar: _isSaving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isCheckedIn ? Icons.check_circle : Icons.power_settings_new,
                size: 16,
                color: isCheckedIn ? Colors.green : Colors.grey,
              ),
        onPressed: _isSaving ? null : _toggleAttendance,
      ),
    );

    if (!widget.showStatus) return action;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        action,
        Text(
          status,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isCheckedIn ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
