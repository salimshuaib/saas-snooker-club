import 'package:flutter/material.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:gap/gap.dart';

class AlarmOverlay extends StatelessWidget {
  final AlarmInfo alarm;

  const AlarmOverlay({Key? key, required this.alarm}) : super(key: key);

  static Future<void> show(BuildContext context, AlarmInfo alarm) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => AlarmOverlay(alarm: alarm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
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
                onEnd: () {
                  // Simple hack to loop animation: not easy with TweenAnimationBuilder alone without state
                  // Since we just want a static bell, we'll keep it simple or use an Icon
                },
                child: Icon(
                  Icons.notifications_active,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
              ),
              const Gap(24),
              Text(
                alarm.tableName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                'Time Over!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    TableAlarmService().dismissAlarm();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'DISMISS',
                    style: TextStyle(
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
    );
  }
}
