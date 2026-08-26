import os
import re

def fix_game_setup():
    path = 'lib/features/games/presentation/widgets/game_setup_sheet.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix the UI block
    old_ui = """                // RACE / RUMMY CONFIG
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
                      hint: 'e.g. 50',
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
                ],"""
                
    new_ui = """                // PLAY MODE CONFIG
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
                    hint: 'e.g. 50',
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
                ],"""
                
    content = content.replace(old_ui, new_ui)
    
    # Fix mode in _startGame
    old_start_game = """      final actualBillingType = _gameType == GameType.standard ? _billingType : BillingType.perMinute;

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final gameSession = GameSession(
        date: dateStr,
        id: FirebaseFirestore.instance.collection('games').doc().id,
        tableId: widget.table.id,
        tableName: widget.table.name,
        tableType: widget.table.type,
        gameType: _gameType,
        mode: _gameType == GameType.standard ? GameMode.solo : _mode,"""
        
    new_start_game = """      final actualBillingType = _gameType == GameType.standard ? _billingType : BillingType.perMinute;
      
      if (combinedPlayers.isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('At least one player must be selected to start a game.'), backgroundColor: AppColors.error),
           );
           setState(() => _isLoading = false);
        }
        return;
      }

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final gameSession = GameSession(
        date: dateStr,
        id: FirebaseFirestore.instance.collection('games').doc().id,
        tableId: widget.table.id,
        tableName: widget.table.name,
        tableType: widget.table.type,
        gameType: _gameType,
        mode: _mode,"""
        
    content = content.replace(old_start_game, new_start_game)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_game_setup()
