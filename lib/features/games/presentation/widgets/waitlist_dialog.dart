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

class _WaitlistEntry {
  PlayerSelection player;
  bool isPaid;
  DateTime addedAt;

  _WaitlistEntry({required this.player, this.isPaid = false, required this.addedAt});
}

class _WaitlistDialogState extends State<WaitlistDialog> {
  late List<_WaitlistEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.players
        .map((p) => _WaitlistEntry(
              player: PlayerSelection(id: p.id, name: p.name),
              isPaid: p.isPaid,
              addedAt: p.addedAt,
            ))
        .toList();
    if (_entries.isEmpty) {
      _entries.add(_WaitlistEntry(
        player: const PlayerSelection(name: ''),
        addedAt: DateTime.now(),
      ));
    }
  }

  void _save() {
    final players = _entries
        .where((e) => e.player.name.trim().isNotEmpty)
        .map(
          (e) => WaitlistPlayer(
            id: e.player.id,
            name: e.player.name.trim(),
            isPaid: e.isPaid,
            addedAt: e.addedAt,
          ),
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
            ...List.generate(_entries.length, (index) {
              final entry = _entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: PlayerSearchField(
                        key: ValueKey('waitlist-player-$index'),
                        initialSelection: entry.player,
                        onSelected: (player) {
                          setState(() => _entries[index].player = player);
                        },
                        hint: 'Player Name',
                      ),
                    ),
                    const Gap(8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _entries[index].isPaid = !_entries[index].isPaid;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: entry.isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          border: Border.all(
                            color: entry.isPaid ? Colors.green : Colors.orange,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.isPaid ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: entry.isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove player',
                      onPressed: () => setState(() {
                        _entries.removeAt(index);
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
            if (_entries.length < 3)
              TextButton.icon(
                onPressed: () => setState(
                  () => _entries.add(_WaitlistEntry(
                    player: const PlayerSelection(name: ''),
                    addedAt: DateTime.now(),
                  )),
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




