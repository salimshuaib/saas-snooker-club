import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';

class WaitlistDetailsSheet extends ConsumerStatefulWidget {
  final GameSession game;

  const WaitlistDetailsSheet({super.key, required this.game});

  @override
  ConsumerState<WaitlistDetailsSheet> createState() => _WaitlistDetailsSheetState();
}

class _WaitlistDetailsSheetState extends ConsumerState<WaitlistDetailsSheet> {
  final Set<String> _selectedForDeletion = {};

  void _deleteSelected(GameSession currentGame) async {
    final newPlayers = currentGame.waitlistPlayers.where((p) => !_selectedForDeletion.contains(p.id ?? p.name)).toList();
    try {
      await ref
          .read(gameSessionControllerProvider.notifier)
          .updateWaitlistPlayers(currentGame.id, currentGame.waitlistPlayers, newPlayers);
      if (mounted) setState(() => _selectedForDeletion.clear());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final runningGamesAsync = ref.watch(runningGamesProvider);
    final runningGames = runningGamesAsync.value ?? [];
    final currentGame = runningGames.firstWhere(
      (g) => g.id == widget.game.id, 
      orElse: () => widget.game,
    );

    final players = currentGame.waitlistPlayers;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Waitlist Details',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          ),
          const Divider(),
          if (players.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No players in waitlist.'),
            )
          else
            ...players.map((player) {
              final timeString = DateFormat('hh:mm a').format(player.addedAt);
              final playerKey = player.id ?? player.name;
              final isSelected = _selectedForDeletion.contains(playerKey);
              return ListTile(
                selected: isSelected,
                selectedColor: Colors.red.shade700,
                selectedTileColor: Colors.red.withValues(alpha: 0.1),
                onLongPress: () {
                  setState(() {
                    _selectedForDeletion.add(playerKey);
                  });
                },
                onTap: () {
                  if (_selectedForDeletion.isNotEmpty) {
                    setState(() {
                      if (isSelected) _selectedForDeletion.remove(playerKey);
                      else _selectedForDeletion.add(playerKey);
                    });
                  }
                },
                title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Added at $timeString'),
                trailing: _selectedForDeletion.isNotEmpty 
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) _selectedForDeletion.add(playerKey);
                          else _selectedForDeletion.remove(playerKey);
                        });
                      }
                    )
                  : InkWell(
                      onTap: () async {
                        // Toggle payment status
                        final newPlayers = players.map((p) {
                          if (p.id == player.id && p.name == player.name) {
                            return p.copyWith(isPaid: !p.isPaid);
                          }
                          return p;
                        }).toList();
                        
                        try {
                          await ref
                              .read(gameSessionControllerProvider.notifier)
                              .updateWaitlistPlayers(currentGame.id, currentGame.waitlistPlayers, newPlayers);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $error')),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: player.isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          border: Border.all(
                            color: player.isPaid ? Colors.green : Colors.orange,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          player.isPaid ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: player.isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ),
              );
            }),
          if (_selectedForDeletion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('Delete Selected (${_selectedForDeletion.length})'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _deleteSelected(currentGame),
              ),
            ),
        ],
      ),
    );
  }
}

