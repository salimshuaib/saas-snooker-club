import os

filepath = 'lib/features/settings/presentation/screens/administrative_settings_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_listtile = """              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Frame Grace Period (Mins)'),
                  subtitle: const Text(
                    'Time allowed before overtime charge begins',
                  ),
                  trailing: DropdownButton<int>(
                    value: settings.game.frameGracePeriodMinutes,
                    underline: const SizedBox(),
                    items: [10, 15, 20, 25, 30].map((mins) {
                      return DropdownMenuItem(
                        value: mins,
                        child: Text('$mins Mins'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateGameSettings(
                          settings.game.copyWith(frameGracePeriodMinutes: val),
                        );
                      }
                    },
                  ),
                ),"""

new_listtile = """              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default Grace Period (Mins)'),
                  subtitle: const Text(
                    'Time allowed before overtime charge begins',
                  ),
                  trailing: DropdownButton<int>(
                    value: settings.game.frameGracePeriodMinutes,
                    underline: const SizedBox(),
                    items: [10, 15, 20, 25, 30, 45, 60].map((mins) {
                      return DropdownMenuItem(
                        value: mins,
                        child: Text('$mins Mins'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateGameSettings(
                          settings.game.copyWith(frameGracePeriodMinutes: val),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Indian Pool Grace Period'),
                  trailing: DropdownButton<int>(
                    value: settings.game.indianPoolGracePeriodMinutes,
                    underline: const SizedBox(),
                    items: [10, 15, 20, 25, 30, 45, 60].map((mins) {
                      return DropdownMenuItem(
                        value: mins,
                        child: Text('$mins Mins'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateGameSettings(
                          settings.game.copyWith(indianPoolGracePeriodMinutes: val),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('American Pool Grace Period'),
                  trailing: DropdownButton<int>(
                    value: settings.game.americanPoolGracePeriodMinutes,
                    underline: const SizedBox(),
                    items: [10, 15, 20, 25, 30, 45, 60].map((mins) {
                      return DropdownMenuItem(
                        value: mins,
                        child: Text('$mins Mins'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateGameSettings(
                          settings.game.copyWith(americanPoolGracePeriodMinutes: val),
                        );
                      }
                    },
                  ),
                ),"""

text = text.replace(old_listtile, new_listtile)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
