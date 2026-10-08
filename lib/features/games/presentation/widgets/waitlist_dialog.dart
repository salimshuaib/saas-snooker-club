import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

class WaitlistDialog extends StatefulWidget {
  final List<String> existingNames;

  const WaitlistDialog({super.key, this.existingNames = const []});

  @override
  State<WaitlistDialog> createState() => _WaitlistDialogState();
}

class _WaitlistDialogState extends State<WaitlistDialog> {
  PlayerSelection _player = const PlayerSelection(name: '');
  bool _isPaid = false;

  void _save() {
    final name = _player.name.trim();
    if (name.isEmpty) {
      Navigator.of(context).pop(<WaitlistPlayer>[]);
      return;
    }
    
    if (widget.existingNames.map((e) => e.toLowerCase()).contains(name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Player $name is already in the waitlist.')),
      );
      return;
    }

    final newPlayer = WaitlistPlayer(
      id: _player.id,
      name: name,
      isPaid: _isPaid,
      addedAt: DateTime.now(),
    );

    Navigator.of(context).pop([newPlayer]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add to Waitlist',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              'Add a player to the waitlist queue.',
              style: theme.textTheme.bodySmall,
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: PlayerSearchField(
                    key: const ValueKey('waitlist-player-input'),
                    initialSelection: _player,
                    onSelected: (player) {
                      setState(() => _player = player);
                    },
                    hint: 'Player Name',
                  ),
                ),
                const Gap(8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPaid = !_isPaid;
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isPaid ? Colors.green : Colors.orange,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isPaid ? 'PAID' : 'UNPAID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Gap(8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
