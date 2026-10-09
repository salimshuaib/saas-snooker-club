import sys

path = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''                  const _RealTimeClockWidget(),
                ],
              ),'''

new_code = '''                  const _RealTimeClockWidget(),
                  if (club?.clubName == 'Only We Have A Club' || club?.slug == 'cuezone')
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Wipe CueZone Data',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Wipe All Data?'),
                            content: const Text('This will permanently delete all games, tables data, players, and credit history for this club.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Yes, Wipe Data')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(gamesRepositoryProvider).wipeCueZoneData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wipe complete!'), backgroundColor: Colors.green));
                        }
                      },
                    ),
                ],
              ),'''

content = content.replace(old_code, new_code)
if "import 'package:snooker_club/features/games/providers/games_providers.dart';" not in content:
    content = "import 'package:snooker_club/features/games/providers/games_providers.dart';\n" + content

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched dashboard_screen.dart')
