import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

class BookingSettingsSheet extends ConsumerStatefulWidget {
  final BookingSettings initialSettings;

  const BookingSettingsSheet({
    super.key,
    required this.initialSettings,
  });

  @override
  ConsumerState<BookingSettingsSheet> createState() =>
      _BookingSettingsSheetState();
}

class _BookingSettingsSheetState extends ConsumerState<BookingSettingsSheet> {
  late bool _isEnabled;
  late int _slotDurationMinutes;
  late String _openingTimeStr;
  late String _closingTimeStr;
  late int _advanceBookingDays;
  late bool _allowSameDayBooking;
  late bool _requireApproval;
  late List<int> _activeDays;

  bool _isSaving = false;

  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];
  final List<int> _advanceOptions = [1, 3, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialSettings.isEnabled;
    _slotDurationMinutes = widget.initialSettings.slotDurationMinutes;
    _openingTimeStr = widget.initialSettings.openingTime;
    _closingTimeStr = widget.initialSettings.closingTime;
    _advanceBookingDays = widget.initialSettings.advanceBookingDays;
    _allowSameDayBooking = widget.initialSettings.allowSameDayBooking;
    _requireApproval = widget.initialSettings.requireApproval;
    _activeDays = List<int>.from(widget.initialSettings.activeDays);
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return const TimeOfDay(hour: 10, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDisplayTime(String timeStr) {
    final tod = _parseTime(timeStr);
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  Future<void> _pickTime(bool isOpening) async {
    final initialTime = _parseTime(isOpening ? _openingTimeStr : _closingTimeStr);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTimeStr = _formatTimeOfDay(picked);
        } else {
          _closingTimeStr = _formatTimeOfDay(picked);
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updated = widget.initialSettings.copyWith(
        isEnabled: _isEnabled,
        slotDurationMinutes: _slotDurationMinutes,
        openingTime: _openingTimeStr,
        closingTime: _closingTimeStr,
        advanceBookingDays: _advanceBookingDays,
        allowSameDayBooking: _allowSameDayBooking,
        requireApproval: _requireApproval,
        activeDays: _activeDays..sort(),
      );

      await ref
          .read(appSettingsProvider.notifier)
          .updateBookingSettings(updated);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking time slots & rules updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysOfWeek = [
      {'val': 1, 'label': 'Mon'},
      {'val': 2, 'label': 'Tue'},
      {'val': 3, 'label': 'Wed'},
      {'val': 4, 'label': 'Thu'},
      {'val': 5, 'label': 'Fri'},
      {'val': 6, 'label': 'Sat'},
      {'val': 7, 'label': 'Sun'},
    ];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule_send,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const Gap(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Slots & Booking Rules',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Control customer time slots for your booking website',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView(
              children: [
                // 1. Enable Online Booking
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Online Booking Website',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Allow customers to book tables online via your club link',
                  ),
                  value: _isEnabled,
                  onChanged: (val) => setState(() => _isEnabled = val),
                ),
                const Divider(),

                // 2. Slot Duration
                const Gap(8),
                Text(
                  'Slot Duration (Minutes)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Length of each selectable booking block on your website',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durationOptions.map((mins) {
                    final selected = _slotDurationMinutes == mins;
                    String label = '$mins Mins';
                    if (mins == 60) label = '1 Hour';
                    if (mins == 90) label = '1.5 Hours';
                    if (mins == 120) label = '2 Hours';

                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _slotDurationMinutes = mins);
                      },
                    );
                  }).toList(),
                ),
                const Gap(16),
                const Divider(),

                // 3. Operating Hours
                const Gap(8),
                Text(
                  'Operating Hours (Slot Boundaries)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Website will generate slots between opening and closing time',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.wb_sunny_outlined,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const Gap(8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Opening Time',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _formatDisplayTime(_openingTimeStr),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.nights_stay_outlined,
                                color: Colors.indigoAccent,
                                size: 20,
                              ),
                              const Gap(8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Closing Time',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _formatDisplayTime(_closingTimeStr),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                const Divider(),

                // 4. Advance Booking Limit
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advance Booking Window',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Maximum days in advance customers can book',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    DropdownButton<int>(
                      value: _advanceBookingDays,
                      underline: const SizedBox(),
                      items: _advanceOptions.map((days) {
                        return DropdownMenuItem(
                          value: days,
                          child: Text('$days ${days == 1 ? 'Day' : 'Days'}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _advanceBookingDays = val);
                      },
                    ),
                  ],
                ),
                const Gap(12),
                const Divider(),

                // 5. Booking Controls Switches
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Allow Same-Day Booking',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Permit bookings for the current day',
                  ),
                  value: _allowSameDayBooking,
                  onChanged: (val) => setState(() => _allowSameDayBooking = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Require Manager Approval',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Online bookings start as unconfirmed and require approval',
                  ),
                  value: _requireApproval,
                  onChanged: (val) => setState(() => _requireApproval = val),
                ),
                const Divider(),

                // 6. Active Days
                const Gap(8),
                Text(
                  'Active Operational Days',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Days when online booking website accepts slot reservations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(8),
                Wrap(
                  spacing: 6,
                  children: daysOfWeek.map((day) {
                    final dayVal = day['val'] as int;
                    final isSelected = _activeDays.contains(dayVal);
                    return FilterChip(
                      label: Text(day['label'] as String),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _activeDays.add(dayVal);
                          } else {
                            if (_activeDays.length > 1) {
                              _activeDays.remove(dayVal);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const Gap(16),
              ],
            ),
          ),
          const Divider(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? 'Saving Changes...' : 'Save & Sync Slot Controls'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
