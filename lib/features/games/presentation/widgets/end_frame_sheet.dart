import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class EndFrameSheet extends ConsumerStatefulWidget {
  final GameSession session;
  final bool isEndingMatch;

  const EndFrameSheet({
    super.key,
    required this.session,
    this.isEndingMatch = false,
  });

  @override
  ConsumerState<EndFrameSheet> createState() => _EndFrameSheetState();
}

class _EndFrameSheetState extends ConsumerState<EndFrameSheet> {
  String? _selectedWinner;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTeam = widget.session.mode == GameMode.team;

    // Available winners
    List<String> winnerOptions = [];
    if (isTeam) {
      if (widget.session.teamA.isNotEmpty) winnerOptions.add('Team A');
      if (widget.session.teamB.isNotEmpty) winnerOptions.add('Team B');
    } else {
      winnerOptions.addAll(widget.session.allPlayers);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'End Frame ${widget.session.framesPlayed + 1}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Gap(16),
          Text('Who won this frame?', style: theme.textTheme.titleMedium),
          const Gap(12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: winnerOptions.map((winner) {
              final isSelected = _selectedWinner == winner;
              return ChoiceChip(
                label: Text(winner),
                selected: isSelected,
                onSelected: (val) {
                  setState(() => _selectedWinner = val ? winner : null);
                },
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const Gap(32),
          if (widget.isEndingMatch)
            FilledButton(
              onPressed: _selectedWinner == null || _isLoading ? null : _saveAndEndMatch,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('End Match & Bill', style: TextStyle(fontSize: 16)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectedWinner == null || _isLoading ? null : _saveAndEndMatch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('End Match', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedWinner == null || _isLoading ? null : _saveAndNextRound,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Next Round', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          const Gap(24),
        ],
      ),
    );
  }

  Future<void> _saveAndNextRound() async {
    await _saveRound(false);
  }

  Future<void> _saveAndEndMatch() async {
    await _saveRound(true);
  }

  Future<void> _saveRound(bool endMatch) async {
    if (_selectedWinner == null) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(gamesRepositoryProvider);
      final newRounds = List<GameRound>.from(widget.session.rounds);
      
      final isTeam = widget.session.mode == GameMode.team;
      String? loser;
      if (isTeam) {
        loser = _selectedWinner == 'Team A' ? 'Team B' : 'Team A';
      } else if (widget.session.allPlayers.length == 2) {
        loser = widget.session.allPlayers.firstWhere((p) => p != _selectedWinner, orElse: () => '');
      }

      final newRound = GameRound(
        roundNumber: widget.session.framesPlayed + 1,
        winner: _selectedWinner,
        loser: loser,
        roundCost: 0.0, 
      );
      newRounds.add(newRound);

      final newTotalFrames = endMatch ? widget.session.framesPlayed : widget.session.totalFrames;
      final newFramesPlayed = endMatch ? widget.session.framesPlayed : widget.session.framesPlayed + 1;

      await repo.updateGameRounds(
        widget.session.id,
        newRounds,
        newTotalFrames,
        newFramesPlayed,
      );

      if (mounted) {
        Navigator.pop(context, endMatch);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
