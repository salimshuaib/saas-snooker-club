import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

class WaitlistDialog extends StatefulWidget {
  final List<WaitlistPlayer> players;

  const WaitlistDialog({super.key, required this.players});

  @override
  State<WaitlistDialog> createState() => _WaitlistDialogState();
}

class _WaitlistDialogState extends State<WaitlistDialog> {
  late List<PlayerSelection> _players;

  @override
  void initState() {
    super.initState();
    _players = widget.players
        .map((player) => PlayerSelection(id: player.id, name: player.name))
        .toList();
    if (_players.isEmpty) _players.add(const PlayerSelection(name: ''));
  }

  void _save() {
    final players = _players
        .where((player) => player.name.trim().isNotEmpty)
        .map(
          (player) => WaitlistPlayer(id: player.id, name: player.name.trim()),
        )
        .toList();
    final names = players.map((player) => player.name.toLowerCase()).toSet();
    if (names.length != players.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A player can only be added once.')),
      );
      return;
    }
    Navigator.of(context).pop(players);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Waitlist'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add up to 3 players for the next game.',
              style: theme.textTheme.bodySmall,
            ),
            const Gap(16),
            ...List.generate(_players.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: PlayerSearchField(
                        key: ValueKey('waitlist-player-$index'),
                        initialSelection: _players[index],
                        onSelected: (player) {
                          setState(() => _players[index] = player);
                        },
                        hint: 'Player Name',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove player',
                      onPressed: () => setState(() {
                        _players.removeAt(index);
                      }),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_players.length < 3)
              TextButton.icon(
                onPressed: () => setState(
                  () => _players.add(const PlayerSelection(name: '')),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Player'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
