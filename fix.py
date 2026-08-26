import re

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's fix the broken _buildStepContent
broken_pattern = re.compile(r'  Widget _buildStepContent\(ThemeData theme\) \{.*?case 2:\n      children: \[', re.DOTALL)

fixed_step_content = '''  Widget _buildStepContent(ThemeData theme) {
    switch (_step) {
      case 0:
        return _buildPlayersStep(theme);
      case 1:
        return _buildBillingStep(theme);
      case 2:
        return _buildMatchTypeStep(theme);
      case 3:
        return _buildFramesStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlayersStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game Type Selection
        Text('Game Type', style: theme.textTheme.labelMedium),
        const Gap(8),
        Row(
          children: GameType.values.where((type) {
            if (type == GameType.rummy && _tableType != TableType.snooker) return false;
            return true;
          }).map((type) {
            final isSelected = _gameType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _gameType = type;
                  if (type != GameType.standard && _teamASelections.length < 2) {
                    if (_teamASelections.isEmpty) _teamASelections.add(null);
                    if (_teamASelections.length == 1) _teamASelections.add(null);
                  }
                }),
                child: Container(
                  margin: EdgeInsets.only(right: type != GameType.values.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(20),

        // Mode Selection
        Text('Mode', style: theme.textTheme.labelMedium),
        const Gap(8),
        Row(
          children: GameMode.values.map((mode) {
            final isSelected = _mode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _mode = mode),
                child: Container(
                  margin:
                      EdgeInsets.only(right: mode == GameMode.solo ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    mode == GameMode.solo ? 'Solo' : 'Team',
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(20),

        if (_gameType == GameType.race) ...[
          Text('Target Points', style: theme.textTheme.labelMedium),
          const Gap(8),
          AppTextField(
            hint: 'e.g., 100',
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => _targetPoints = int.tryParse(val)),
          ),
          const Gap(20),
        ],

        if (_mode == GameMode.solo) ...[
          if (_gameType == GameType.standard) ...[
            Text('Player Name', style: theme.textTheme.labelMedium),
            const Gap(8),
            PlayerSearchField(hint: 'Player 1', onSelected: (val) => setState(() {
              if (_teamASelections.isEmpty) _teamASelections.add(null);
              _teamASelections[0] = val;
            })),
          ] else ...[
            _TeamPlayerFields(
              teamLabel: 'Players (Max 10)',
              selections: _teamASelections,
              onChange: (i, val) => setState(() => _teamASelections[i] = val),
              onAdd: _teamASelections.length < 10 ? () => setState(() => _teamASelections.add(null)) : null,
              onRemove: _teamASelections.length > 2 ? (i) => setState(() => _teamASelections.removeAt(i)) : null,
            ),
          ]
        ] else ...[
          _TeamPlayerFields(
            teamLabel: 'Team A (Max 5)',
            selections: _teamASelections,
            onChange: (i, val) => setState(() => _teamASelections[i] = val),
            onAdd: _teamASelections.length < 5 ? () => setState(() => _teamASelections.add(null)) : null,
            onRemove: _teamASelections.length > 1 ? (i) => setState(() => _teamASelections.removeAt(i)) : null,
          ),
          const Gap(20),
          _TeamPlayerFields(
            teamLabel: 'Team B (Max 5)',
            selections: _teamBSelections,
            onChange: (i, val) => setState(() => _teamBSelections[i] = val),
            onAdd: _teamBSelections.length < 5 ? () => setState(() => _teamBSelections.add(null)) : null,
            onRemove: _teamBSelections.length > 1 ? (i) => setState(() => _teamBSelections.removeAt(i)) : null,
          ),
        ],
      ],
    );
  }

  Widget _buildBillingStep(ThemeData theme) {
    final supported = TablePricingConfig.supportedBillingTypes(_tableType);
    return Column(
      children: ['''

content = broken_pattern.sub(fixed_step_content, content)

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)
