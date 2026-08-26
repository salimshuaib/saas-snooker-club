import re

def rewrite_game_setup():
    file_path = 'lib/features/games/presentation/widgets/game_setup_sheet.dart'
    # I'll just provide a completely fresh implementation since it's much simpler.
    
    content = """import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';

class GameSetupSheet extends ConsumerStatefulWidget {
  final TableModel table;
  final String employeeId;

  const GameSetupSheet({
    super.key,
    required this.table,
    required this.employeeId,
  });

  @override
  ConsumerState<GameSetupSheet> createState() => _GameSetupSheetState();
}

class _GameSetupSheetState extends ConsumerState<GameSetupSheet> {
  // Selections
  late TableType _tableType;
  GameType _gameType = GameType.standard;
  int? _targetPoints;
  GameMode _mode = GameMode.solo;
  
  // Standard configs
  BillingType _billingType = BillingType.perMinute;
  MatchType _matchType = TablePricingConfig.defaultMatchType;
  int _totalFrames = 1;

  // Players
  final List<PlayerSelection?> _teamASelections = [null];
  final List<PlayerSelection?> _teamBSelections = [null];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tableType = widget.table.type;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configure Game', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(widget.table.name, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Game Type Selection
                Text('Game Type', style: theme.textTheme.labelMedium),
                const Gap(8),
                DropdownButtonFormField<GameType>(
                  value: _gameType,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: GameType.values
                      .where((type) {
                        if (type == GameType.rummy && _tableType != TableType.snooker) {
                          return false;
                        }
                        return true;
                      })
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _gameType = val;
                        // Reset player counts to minimums
                        if (val != GameType.standard && _teamASelections.length < 2) {
                          _teamASelections.clear();
                          _teamASelections.addAll([null, null]);
                        }
                      });
                    }
                  },
                ),
                const Gap(24),

                // STANDARD CONFIG
                if (_gameType == GameType.standard) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Billing Type', style: theme.textTheme.labelMedium),
                            const Gap(8),
                            DropdownButtonFormField<BillingType>(
                              value: _billingType,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: BillingType.values.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              )).toList(),
                              onChanged: (v) => setState(() => _billingType = v!),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Match Type', style: theme.textTheme.labelMedium),
                            const Gap(8),
                            DropdownButtonFormField<MatchType>(
                              value: _matchType,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: MatchType.values.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              )).toList(),
                              onChanged: (v) => setState(() => _matchType = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_billingType == BillingType.perFrame) ...[
                    const Gap(24),
                    Text('Total Frames', style: theme.textTheme.labelMedium),
                    const Gap(8),
                    AppTextField(
                      initialValue: _totalFrames.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _totalFrames = int.tryParse(val) ?? 1,
                    ),
                  ],
                ],

                // RACE / RUMMY CONFIG
                if (_gameType != GameType.standard) ...[
                  Text('Play Mode', style: theme.textTheme.labelMedium),
                  const Gap(8),
                  Row(
                    children: GameMode.values.map((mode) {
                      final isSelected = _mode == mode;
                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _mode = mode;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : theme.colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                mode.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(24),

                  if (_gameType == GameType.race) ...[
                    Text('Target Points (Optional)', style: theme.textTheme.labelMedium),
                    const Gap(8),
                    AppTextField(
                      hintText: 'e.g. 50',
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        _targetPoints = int.tryParse(val);
                      },
                    ),
                    const Gap(24),
                  ],

                  if (_mode == GameMode.solo) ...[
                    _buildTeamSection('Players', _teamASelections, 10, theme),
                  ] else ...[
                    _buildTeamSection('Team A', _teamASelections, 5, theme),
                    const Gap(24),
                    _buildTeamSection('Team B', _teamBSelections, 5, theme),
                  ],
                ],
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Start Game', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(String title, List<PlayerSelection?> selections, int maxPlayers, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Gap(12),
        ...List.generate(selections.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: PlayerSearchField(
                    initialSelection: selections[index],
                    onSelected: (selection) {
                      setState(() {
                        selections[index] = selection;
                      });
                    },
                  ),
                ),
                if (selections.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        selections.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
          );
        }),
        if (selections.length < maxPlayers)
          TextButton.icon(
            onPressed: () {
              setState(() {
                selections.add(null);
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Player'),
          ),
      ],
    );
  }

  Future<void> _startGame() async {
    setState(() => _isLoading = true);

    try {
      final teamAPlayers = _teamASelections
          .where((p) => p != null && p.displayName.trim().isNotEmpty)
          .map((p) => p!)
          .toList();

      final teamBPlayers = _mode == GameMode.team
          ? _teamBSelections
              .where((p) => p != null && p.displayName.trim().isNotEmpty)
              .map((p) => p!)
              .toList()
          : <PlayerSelection>[];

      final gameSession = GameSession(
        id: FirebaseFirestore.instance.collection('games').doc().id,
        tableId: widget.table.id,
        clubId: widget.table.clubId,
        gameType: _gameType,
        mode: _gameType == GameType.standard ? GameMode.solo : _mode,
        startTime: DateTime.now(),
        status: GameStatus.active,
        targetPoints: _targetPoints,
        billingType: _gameType == GameType.standard ? _billingType : BillingType.perMinute,
        matchType: _gameType == GameType.standard ? _matchType : MatchType.friendly,
        totalFrames: (_gameType == GameType.standard && _billingType == BillingType.perFrame) ? _totalFrames : null,
        teamAPlayers: teamAPlayers,
        teamBPlayers: teamBPlayers,
        createdByUserId: widget.employeeId,
      );

      await ref.read(gamesRepositoryProvider).createGameSession(
            gameSession,
            widget.table,
            widget.employeeId,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
"""
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    rewrite_game_setup()
