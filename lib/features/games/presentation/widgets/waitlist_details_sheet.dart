import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';

class WaitlistDetailsSheet extends ConsumerWidget {
  final GameSession game;

  const WaitlistDetailsSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // We can listen to the game session to get real-time updates while sheet is open
    // However, if we just pass game, it won't rebuild. Let's watch it.
    final runningGamesAsync = ref.watch(runningGamesProvider);
    final runningGames = runningGamesAsync.value ?? [];
    // Find the latest game object
    final currentGame = runningGames.firstWhere(
      (g) => g.id == game.id, 
      orElse: () => game,
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
              return ListTile(
                title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Added at $timeString'),
                trailing: InkWell(
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
        ],
      ),
    );
  }
}
