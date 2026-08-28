path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# 1. Update _handleEndGame to handle GameType.race
# Right before // Non-perFrame billing (hourly/per-minute), go directly to billing
new_race_logic = '''      // Race Billing: Ask who won, then go to billing
      if (game.gameType == GameType.race) {
        if (!context.mounted) return;
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => _RoundCompletionDialog(game: game, isRace: true),
        );
        if (result == null || !mounted || !context.mounted) return;

        final winner = result['winner'] as String;
        final Map<String, int> fakePoints = {};
        if (game.mode == GameMode.team) {
          fakePoints['Team A'] = winner == 'Team A' ? 1 : 0;
          fakePoints['Team B'] = winner == 'Team B' ? 1 : 0;
        } else {
          for (final p in game.allPlayers) {
            fakePoints[p] = p == winner ? 1 : 0;
          }
        }
        
        final updatedSession = game.copyWith(playerPoints: fakePoints);
        if (mounted && context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BillingScreen(session: updatedSession),
            ),
          );
        }
        return;
      }

      // Non-perFrame billing (hourly/per-minute), go directly to billing'''

content = content.replace('      // Non-perFrame billing (hourly/per-minute), go directly to billing', new_race_logic)

# 2. Update _RoundCompletionDialog to support isRace flag
content = content.replace('const _RoundCompletionDialog({required this.game});', 'final bool isRace;\n  const _RoundCompletionDialog({required this.game, this.isRace = false});')

dialog_build = '''    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final candidates = widget.game.mode == GameMode.team
          ? ['Team A', 'Team B']
          : widget.game.allPlayers;
      final needsLoserSelect =
          !widget.isRace && widget.game.mode != GameMode.team && widget.game.allPlayers.length > 2;

      return AlertDialog(
        title: Text(widget.isRace ? 'Game Complete' : 'Round \ Complete'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isRace ? 'Who won this game?' : 'Who won this round?',
'''
content = re.sub(r'    @override\s+Widget build\(BuildContext context\) \{.*?Text\(\s*\'Who won this round\?\',', dialog_build, content, flags=re.DOTALL)

buttons_replace = '''
              if (widget.isRace) ...[
                const Gap(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Gap(8),
                    FilledButton(
                      onPressed: _selectedWinner == null
                          ? null
                          : () {
                              Navigator.pop(context, {
                                'winner': _selectedWinner,
                              });
                            },
                      child: const Text('Continue to Billing'),
                    ),
                  ],
                ),
              ] else ...[
                const Gap(24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectedWinner == null
                            ? null
                            : () {
                                Navigator.pop(context, {
                                  'winner': _selectedWinner,
                                  'loser': _selectedLoser,
                                  'continue': false,
                                });
                              },
                        child: const Text('Finish & Bill'),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedWinner == null
                            ? null
                            : () {
                                Navigator.pop(context, {
                                  'winner': _selectedWinner,
                                  'loser': _selectedLoser,
                                  'continue': true,
                                });
                              },
                        child: const Text('Play Another'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }'''

content = re.sub(r'              const Gap\(24\),.*?\]\,\s*\)\,\s*\)\,\s*\)\;\s*\}', buttons_replace, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
