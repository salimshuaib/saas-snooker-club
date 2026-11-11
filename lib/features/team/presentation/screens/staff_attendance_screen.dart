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

enum PerformanceScope {
  day,
  month,
  allTime,
  custom,
}

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  final StaffMember staffMember;

  const StaffAttendanceScreen({super.key, required this.staffMember});

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  PerformanceScope _performanceScope = PerformanceScope.month;
  DateTimeRange? _customPerformanceRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(staffAttendanceProvider(widget.staffMember.id));
    final activityAsync = ref.watch(staffActivityDataProvider(widget.staffMember.id));
    
    final currentStaff = ref.watch(currentStaffProvider).value;
    final isOwner = currentStaff?.role == StaffRole.owner;

    final allLogs = attendanceAsync.value ?? [];
    final monthLogs = allLogs.where((l) {
      return l.checkInTime.year == _currentMonth.year && l.checkInTime.month == _currentMonth.month;
    }).toList();

    final uniqueWorkDays = monthLogs.map((l) => l.dateString).toSet().length;

    Duration totalMonthDuration = Duration.zero;
    for (final log in monthLogs) {
      if (log.checkOutTime != null) {
        final diff = log.checkOutTime!.difference(log.checkInTime);
        if (!diff.isNegative) totalMonthDuration += diff;
      } else if (isSameDay(log.checkInTime, DateTime.now())) {
        final diff = DateTime.now().difference(log.checkInTime);
        if (!diff.isNegative) totalMonthDuration += diff;
      }
    }

    final selectedDateStr = AttendanceLog.generateDateString(_selectedDate);
    final selectedDayLogs = allLogs.where((l) => l.dateString == selectedDateStr).toList();
    Duration selectedDayDuration = Duration.zero;
    bool hasActiveShiftOnSelectedDay = false;
    for (final log in selectedDayLogs) {
      if (log.checkOutTime != null) {
        final diff = log.checkOutTime!.difference(log.checkInTime);
        if (!diff.isNegative) selectedDayDuration += diff;
      } else if (isSameDay(log.checkInTime, DateTime.now())) {
        hasActiveShiftOnSelectedDay = true;
        final diff = DateTime.now().difference(log.checkInTime);
        if (!diff.isNegative) selectedDayDuration += diff;
      }
    }

    int filteredGamesCount = 0;
    int filteredSalesCount = 0;
    String performancePeriodSubtitle = '';

    activityAsync.whenData((activity) {
      switch (_performanceScope) {
        case PerformanceScope.day:
          performancePeriodSubtitle = DateFormat('d MMM yyyy').format(_selectedDate);
          filteredGamesCount = activity.games.where((g) => isSameDay(g.timestamp, _selectedDate)).length;
          filteredSalesCount = activity.sales.where((s) => isSameDay(s.timestamp, _selectedDate)).length;
          break;
        case PerformanceScope.month:
          performancePeriodSubtitle = DateFormat('MMMM yyyy').format(_currentMonth);
          final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
          final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1).subtract(const Duration(milliseconds: 1));
          filteredGamesCount = activity.games.where((g) => !g.timestamp.isBefore(startOfMonth) && !g.timestamp.isAfter(endOfMonth)).length;
          filteredSalesCount = activity.sales.where((s) => !s.timestamp.isBefore(startOfMonth) && !s.timestamp.isAfter(endOfMonth)).length;
          break;
        case PerformanceScope.allTime:
          performancePeriodSubtitle = 'All-Time';
          filteredGamesCount = activity.games.length;
          filteredSalesCount = activity.sales.length;
          break;
        case PerformanceScope.custom:
          if (_customPerformanceRange != null) {
            final start = DateTime(_customPerformanceRange!.start.year, _customPerformanceRange!.start.month, _customPerformanceRange!.start.day, 0, 0, 0);
            final end = DateTime(_customPerformanceRange!.end.year, _customPerformanceRange!.end.month, _customPerformanceRange!.end.day, 23, 59, 59, 999);
            performancePeriodSubtitle = '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
            filteredGamesCount = activity.games.where((g) => !g.timestamp.isBefore(start) && !g.timestamp.isAfter(end)).length;
            filteredSalesCount = activity.sales.where((s) => !s.timestamp.isBefore(start) && !s.timestamp.isAfter(end)).length;
          } else {
            performancePeriodSubtitle = 'All-Time';
            filteredGamesCount = activity.games.length;
            filteredSalesCount = activity.sales.length;
          }
          break;
      }
    });

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

            const SizedBox(height: 20),

            // Monthly Attendance Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assessment_outlined, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('MMMM yyyy').format(_currentMonth)} Summary',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('MMMM').format(_currentMonth),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Work Days
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Work Days',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$uniqueWorkDays ${uniqueWorkDays == 1 ? 'Day' : 'Days'}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Attended this month',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Working Hours
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 16, color: Colors.amber),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Working Hours',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(totalMonthDuration),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                uniqueWorkDays > 0 ? 'Avg ${_formatAvgHours(totalMonthDuration, uniqueWorkDays)} / day' : 'No logs yet',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Selected Day Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Details for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (selectedDayDuration > Duration.zero || hasActiveShiftOnSelectedDay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasActiveShiftOnSelectedDay
                          ? AppColors.success.withOpacity(0.15)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasActiveShiftOnSelectedDay
                            ? AppColors.success.withOpacity(0.4)
                            : theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Total: ${_formatDuration(selectedDayDuration)}${hasActiveShiftOnSelectedDay ? ' (active)' : ''}',
                      style: TextStyle(
                        color: hasActiveShiftOnSelectedDay ? AppColors.success : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            attendanceAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (logs) {
                final dateString = AttendanceLog.generateDateString(_selectedDate);
                final dayLogs = logs.where((l) => l.dateString == dateString).toList();
                
                if (dayLogs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'No attendance recorded for ${DateFormat('MMM d, yyyy').format(_selectedDate)}.',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (isOwner) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showEditDialog(context, null),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Missing Attendance'),
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: dayLogs.map((log) {
                    final isShiftActive = log.checkOutTime == null && isSameDay(log.checkInTime, DateTime.now());
                    final shiftDuration = log.checkOutTime != null
                        ? log.checkOutTime!.difference(log.checkInTime)
                        : (isShiftActive ? DateTime.now().difference(log.checkInTime) : null);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isShiftActive
                              ? AppColors.success.withOpacity(0.15)
                              : theme.colorScheme.primaryContainer,
                          child: Icon(
                            isShiftActive ? Icons.timer : Icons.done_all,
                            color: isShiftActive ? AppColors.success : theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'In: ${DateFormat('hh:mm a').format(log.checkInTime)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Text('  →  '),
                            Text(
                              log.checkOutTime != null
                                  ? 'Out: ${DateFormat('hh:mm a').format(log.checkOutTime!)}'
                                  : 'Active Shift',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isShiftActive ? AppColors.success : null,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (shiftDuration != null)
                                Text(
                                  'Duration: ${_formatDuration(shiftDuration)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (log.autoCheckedOut)
                                const Text('Auto-Checked Out', style: TextStyle(color: Colors.red, fontSize: 12)),
                              if (log.editedByOwner)
                                const Text('Edited by Owner', style: TextStyle(color: Colors.orange, fontSize: 12)),
                            ],
                          ),
                        ),
                        trailing: isOwner 
                            ? IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Attendance',
                                onPressed: () => _showEditDialog(context, log),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Performance Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Performance',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      performancePeriodSubtitle.isNotEmpty ? performancePeriodSubtitle : 'Select filter below',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Dropdown Bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PerformanceScope>(
                        value: _performanceScope,
                        isExpanded: true,
                        alignment: AlignmentDirectional.center,
                        dropdownColor: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        selectedItemBuilder: (context) {
                          return PerformanceScope.values.map((scope) {
                            IconData icon;
                            String label;
                            switch (scope) {
                              case PerformanceScope.day:
                                icon = Icons.today_outlined;
                                label = 'Selected Day (${DateFormat('d MMM yyyy').format(_selectedDate)})';
                                break;
                              case PerformanceScope.month:
                                icon = Icons.calendar_month_outlined;
                                label = 'This Month (${DateFormat('MMMM yyyy').format(_currentMonth)})';
                                break;
                              case PerformanceScope.allTime:
                                icon = Icons.all_inclusive_rounded;
                                label = 'All Time';
                                break;
                              case PerformanceScope.custom:
                                icon = Icons.date_range_outlined;
                                label = _customPerformanceRange != null
                                    ? 'Custom: ${DateFormat('d MMM').format(_customPerformanceRange!.start)} - ${DateFormat('d MMM yyyy').format(_customPerformanceRange!.end)}'
                                    : 'Custom Date Range...';
                                break;
                            }
                            return Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icon, size: 17, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      label,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        items: PerformanceScope.values.map((scope) {
                          IconData icon;
                          String label;
                          switch (scope) {
                            case PerformanceScope.day:
                              icon = Icons.today_outlined;
                              label = 'Selected Day (${DateFormat('d MMM yyyy').format(_selectedDate)})';
                              break;
                            case PerformanceScope.month:
                              icon = Icons.calendar_month_outlined;
                              label = 'This Month (${DateFormat('MMMM yyyy').format(_currentMonth)})';
                              break;
                            case PerformanceScope.allTime:
                              icon = Icons.all_inclusive_rounded;
                              label = 'All Time';
                              break;
                            case PerformanceScope.custom:
                              icon = Icons.date_range_outlined;
                              label = _customPerformanceRange != null
                                  ? 'Custom: ${DateFormat('d MMM').format(_customPerformanceRange!.start)} - ${DateFormat('d MMM yyyy').format(_customPerformanceRange!.end)}'
                                  : 'Custom Date Range...';
                              break;
                          }
                          final isSelected = _performanceScope == scope;
                          return DropdownMenuItem<PerformanceScope>(
                            value: scope,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val == null) return;
                          if (val == PerformanceScope.custom) {
                            await _selectCustomDateRange(context);
                          } else {
                            setState(() => _performanceScope = val);
                          }
                        },
                      ),
                    ),
                  ),
                  if (_performanceScope == PerformanceScope.custom) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      tooltip: 'Change Custom Date Range',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _selectCustomDateRange(context),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            activityAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading stats: $err', style: TextStyle(color: theme.colorScheme.error)),
              ),
              data: (_) {
                return Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sports_esports_outlined, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Games Run',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$filteredGamesCount',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sessions started',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.point_of_sale_outlined, color: AppColors.success, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Quick Sales',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$filteredSalesCount',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sales completed',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                              ),
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

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customPerformanceRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        _customPerformanceRange = picked;
        _performanceScope = PerformanceScope.custom;
      });
    } else if (_customPerformanceRange == null) {
      setState(() {
        _performanceScope = PerformanceScope.month;
      });
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0 && minutes == 0) return '0h 0m';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  String _formatAvgHours(Duration d, int days) {
    if (days <= 0) return '0h';
    final totalMinutes = d.inMinutes;
    final avgMinutes = totalMinutes / days;
    final avgHours = avgMinutes / 60.0;
    return '${avgHours.toStringAsFixed(1)}h';
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
