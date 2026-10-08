import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/domain/models/attendance_log.dart';
import 'package:snooker_club/features/team/providers/attendance_providers.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  final StaffMember staffMember;

  const StaffAttendanceScreen({Key? key, required this.staffMember}) : super(key: key);

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(staffAttendanceProvider(widget.staffMember.id));
    final statsAsync = ref.watch(staffMonthlyStatsProvider(
      (widget.staffMember.id, _currentMonth)
    ));
    
    final currentStaff = ref.watch(currentStaffProvider).value;
    final isOwner = currentStaff?.role == StaffRole.owner;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.staffMember.name}\'s Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Days of week
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(day, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Calendar Grid
            attendanceAsync.when(
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SizedBox(height: 200, child: Center(child: Text('Error: $err'))),
              data: (logs) {
                final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
                final firstDayOffset = _currentMonth.weekday % 7; // Sunday = 0
                final totalSlots = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: totalSlots,
                  itemBuilder: (context, index) {
                    if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    
                    final day = index - firstDayOffset + 1;
                    final cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                    final isSelected = isSameDay(cellDate, _selectedDate);
                    final dateString = AttendanceLog.generateDateString(cellDate);
                    
                    // Find if there's any log for this day
                    final dayLogs = logs.where((l) => l.dateString == dateString).toList();
                    final hasWorked = dayLogs.isNotEmpty;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = cellDate;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : (hasWorked ? theme.colorScheme.primaryContainer : theme.colorScheme.surface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected 
                                  ? theme.colorScheme.onPrimary 
                                  : (hasWorked ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface),
                              fontWeight: isSelected || hasWorked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),
            
            // Selected Day Details
            Text(
              'Details for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            attendanceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (logs) {
                final dateString = AttendanceLog.generateDateString(_selectedDate);
                final dayLogs = logs.where((l) => l.dateString == dateString).toList();
                
                if (dayLogs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('No attendance recorded for this day.'),
                          if (isOwner) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showEditDialog(context, null),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Missing Attendance'),
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: dayLogs.map((log) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Check In: ${DateFormat('hh:mm a').format(log.checkInTime)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check Out: ${log.checkOutTime != null ? DateFormat('hh:mm a').format(log.checkOutTime!) : 'Active'}'),
                          if (log.autoCheckedOut)
                            const Text('Auto-Checked Out', style: TextStyle(color: Colors.red, fontSize: 12)),
                          if (log.editedByOwner)
                            const Text('Edited by Owner', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                      trailing: isOwner 
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(context, log),
                            )
                          : null,
                    ),
                  )).toList(),
                );
              },
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Monthly Stats
            Text(
              'Monthly Performance (${DateFormat('MMMM').format(_currentMonth)})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading stats: $err'),
              data: (stats) {
                return Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '${stats['games']}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Games Run'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '${stats['sales']}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Quick Sales'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showEditDialog(BuildContext context, AttendanceLog? log) {
    TimeOfDay? inTime = log != null ? TimeOfDay.fromDateTime(log.checkInTime) : null;
    TimeOfDay? outTime = log?.checkOutTime != null ? TimeOfDay.fromDateTime(log!.checkOutTime!) : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(log == null ? 'Add Attendance' : 'Edit Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Check In Time'),
                  subtitle: Text(inTime != null ? inTime!.format(context) : 'Not set'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: inTime ?? TimeOfDay.now());
                    if (time != null) setDialogState(() => inTime = time);
                  },
                ),
                ListTile(
                  title: const Text('Check Out Time'),
                  subtitle: Text(outTime != null ? outTime!.format(context) : 'Not set'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: outTime ?? TimeOfDay.now());
                    if (time != null) setDialogState(() => outTime = time);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: inTime == null ? null : () async {
                  Navigator.pop(context);
                  
                  final clubId = ref.read(clubIdProvider);
                  if (clubId == null) return;

                  final checkInDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, inTime!.hour, inTime!.minute);
                  final checkOutDateTime = outTime != null 
                      ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, outTime!.hour, outTime!.minute)
                      : null;

                  final firestore = FirebaseFirestore.instance;
                  final collection = firestore
                      .collection(FirebaseConstants.clubsCollection)
                      .doc(clubId)
                      .collection(FirebaseConstants.attendanceCollection);

                  if (log == null) {
                    final newLogId = '${widget.staffMember.id}_${DateTime.now().millisecondsSinceEpoch}';
                    await collection.doc(newLogId).set({
                      'staffId': widget.staffMember.id,
                      'staffName': widget.staffMember.name,
                      'checkInTime': Timestamp.fromDate(checkInDateTime),
                      'checkOutTime': checkOutDateTime != null ? Timestamp.fromDate(checkOutDateTime) : null,
                      'dateString': AttendanceLog.generateDateString(_selectedDate),
                      'autoCheckedOut': false,
                      'editedByOwner': true,
                    });
                  } else {
                    await collection.doc(log.id).update({
                      'checkInTime': Timestamp.fromDate(checkInDateTime),
                      'checkOutTime': checkOutDateTime != null ? Timestamp.fromDate(checkOutDateTime) : null,
                      'editedByOwner': true,
                      'autoCheckedOut': false, // clear this if owner edited it manually
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}
