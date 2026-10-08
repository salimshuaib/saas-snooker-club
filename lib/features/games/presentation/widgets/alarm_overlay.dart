import 'package:flutter/material.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class AlarmOverlay extends ConsumerStatefulWidget {
  const AlarmOverlay({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => const AlarmOverlay(),
    );
  }

  @override
  ConsumerState<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends ConsumerState<AlarmOverlay> {
  bool _isDismissing = false;

  void _dismissAllAndPop() {
    if (_isDismissing) return;
    _isDismissing = true;
    TableAlarmService().dismissAllAlarms();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ringing alarms directly from the service
    final ringingAlarms = ref.watch(ringingAlarmsProvider).value ?? TableAlarmService().ringingAlarms;
    
    // Auto-close if empty (e.g. dismissed from another device or single dismissed)
    ref.listen(ringingAlarmsProvider, (previous, next) {
      final alarms = next.value ?? [];
      if (alarms.isEmpty) {
        if (!_isDismissing && mounted) {
           _isDismissing = true;
           Navigator.of(context).pop();
        }
      }
    });

    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black87,
        child: Center(
          child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, val, child) {
                  return Transform.scale(
                    scale: val,
                    child: child,
                  );
                },
                child: Icon(
                  Icons.notifications_active,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
              ),
              const Gap(16),
              Text(
                ringingAlarms.length > 1 
                  ? 'Time Over for ${ringingAlarms.length} Tables!'
                  : 'Time Over!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ringingAlarms.length,
                  itemBuilder: (context, index) {
                    final alarm = ringingAlarms[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        alarm.tableName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                           TableAlarmService().dismissAlarmForGame(alarm.gameId);
                           ref.read(gamesRepositoryProvider).updateGameAlarm(alarm.gameId, null);
                        },
                      ),
                    );
                  },
                ),
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    final alarmsCopy = List<AlarmInfo>.from(ringingAlarms);
                    _dismissAllAndPop();
                    for (final a in alarmsCopy) {
                       ref.read(gamesRepositoryProvider).updateGameAlarm(a.gameId, null);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    ringingAlarms.length > 1 ? 'DISMISS ALL' : 'DISMISS',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
