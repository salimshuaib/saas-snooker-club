import re

with open('lib/features/games/presentation/widgets/alarm_overlay.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    ""import 'package:gap/gap.dart';"",
    ""import 'package:gap/gap.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:snooker_club/features/games/providers/games_providers.dart';""
)

content = content.replace(
    ""class AlarmOverlay extends StatelessWidget {"",
    ""class AlarmOverlay extends ConsumerStatefulWidget {""
)

content = content.replace(
    ""const AlarmOverlay({Key? key, required this.alarm}) : super(key: key);"",
    ""const AlarmOverlay({Key? key, required this.alarm}) : super(key: key);\n\n  @override\n  ConsumerState<AlarmOverlay> createState() => _AlarmOverlayState();\n}\n\nclass _AlarmOverlayState extends ConsumerState<AlarmOverlay> {""
)

content = content.replace(""alarm.tableName"", ""widget.alarm.tableName"")

build_method_start = ""\"  @override
  Widget build(BuildContext context) {""\"

build_method_new = ""\"  @override
  Widget build(BuildContext context) {
    ref.listen(runningGamesProvider, (previous, next) {
      final games = next.value ?? [];
      final session = games.where((g) => g.id == widget.alarm.gameId).firstOrNull;
      if (session == null || session.alarmTime == null) {
        TableAlarmService().dismissAlarm();
        if (mounted) {
           Navigator.of(context).pop();
        }
      }
    });""\"
content = content.replace(build_method_start, build_method_new)

dismiss_button_old = ""\"                  onPressed: () {
                    TableAlarmService().dismissAlarm();
                    Navigator.of(context).pop();
                  },""\"

dismiss_button_new = ""\"                  onPressed: () {
                    TableAlarmService().dismissAlarm();
                    ref.read(gamesRepositoryProvider).updateGameAlarm(widget.alarm.gameId, null);
                    Navigator.of(context).pop();
                  },""\"
content = content.replace(dismiss_button_old, dismiss_button_new)

with open('lib/features/games/presentation/widgets/alarm_overlay.dart', 'w', encoding='utf-8') as f:
    f.write(content)
