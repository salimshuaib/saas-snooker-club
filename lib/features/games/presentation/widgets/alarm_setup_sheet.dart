import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';

class AlarmSetupSheet extends StatefulWidget {
  final String gameId;
  final String tableName;

  const AlarmSetupSheet({
    Key? key,
    required this.gameId,
    required this.tableName,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, String gameId, String tableName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AlarmSetupSheet(gameId: gameId, tableName: tableName),
    );
  }

  @override
  State<AlarmSetupSheet> createState() => _AlarmSetupSheetState();
}

class _AlarmSetupSheetState extends State<AlarmSetupSheet> {
  int _selectedMinutes = 5;
  bool _isCustom = false;
  final _customController = TextEditingController();
  
  AlarmInfo? _activeAlarm;
  
  @override
  void initState() {
    super.initState();
    _activeAlarm = TableAlarmService().getAlarmInfo(widget.gameId);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: insets.bottom + 16,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: theme.colorScheme.primary),
              const Gap(12),
              Expanded(
                child: Text(
                  'Set Reminder for ${widget.tableName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          const Gap(16),
          
          if (_activeAlarm != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Alarm active for ${_activeAlarm!.fireAt.hour.toString().padLeft(2, '0')}:${_activeAlarm!.fireAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      TableAlarmService().cancelAlarm(widget.gameId);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            const Gap(24),
            const Text('Change Timer:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(12),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 30].map((mins) {
              final selected = !_isCustom && _selectedMinutes == mins;
              return ChoiceChip(
                label: Text('$mins min'),
                selected: selected,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _isCustom = false;
                      _selectedMinutes = mins;
                    });
                  }
                },
              );
            }).toList()
              ..add(
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _isCustom,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isCustom = true;
                      });
                    }
                  },
                ),
              ),
          ),
          if (_isCustom) ...[
            const Gap(16),
            TextFormField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
              autofocus: true,
              onChanged: (val) {
                _selectedMinutes = int.tryParse(val) ?? 0;
              },
            ),
          ],
          const Gap(32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                if (_selectedMinutes <= 0) return;
                TableAlarmService().setAlarm(
                  gameId: widget.gameId,
                  tableName: widget.tableName,
                  durationMinutes: _selectedMinutes,
                );
                Navigator.pop(context);
              },
              child: Text(
                _activeAlarm != null ? 'Update Reminder' : 'Start Timer',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
