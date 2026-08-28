import re

def replace_block(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the start of _buildPlayersStep
    start_str = "Widget _buildPlayersStep(ThemeData theme) {"
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Could not find _buildPlayersStep")
        return

    # Find the end of _buildPlayersStep
    # We will balance braces to find the end
    brace_count = 0
    end_idx = -1
    for i in range(start_idx + len(start_str) - 1, len(content)):
        if content[i] == '{':
            brace_count += 1
        elif content[i] == '}':
            brace_count -= 1
            if brace_count == 0:
                end_idx = i
                break
                
    if end_idx == -1:
        print("Could not find end of _buildPlayersStep")
        return

    new_method = """Widget _buildPlayersStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName, style: TextStyle(fontWeight: FontWeight.w600)),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _gameType = val;
                if (val != GameType.standard && _teamASelections.length < 2) {
                  if (_teamASelections.isEmpty) _teamASelections.add(null);
                  if (_teamASelections.length == 1) _teamASelections.add(null);
                }
              });
            }
          },
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
                  margin: EdgeInsets.only(right: mode == GameMode.solo ? 8 : 0),
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
            PlayerSearchField(
              hint: 'Player 1',
              onSelected: (val) => setState(() {
                if (_teamASelections.isEmpty) _teamASelections.add(null);
                _teamASelections[0] = val;
              }),
            ),
          ] else ...[
            _TeamPlayerFields(
              teamLabel: 'Players (Max 10)',
              selections: _teamASelections,
              onChange: (i, val) => setState(() => _teamASelections[i] = val),
              onAdd: () {
                if (_teamASelections.length < 10) setState(() => _teamASelections.add(null));
              },
              onRemove: (i) {
                if (_teamASelections.length > 2) setState(() => _teamASelections.removeAt(i));
              },
            ),
          ],
        ] else ...[
          _TeamPlayerFields(
            teamLabel: 'Team A (Max 5)',
            selections: _teamASelections,
            onChange: (i, val) => setState(() => _teamASelections[i] = val),
            onAdd: () {
              if (_teamASelections.length < 5) setState(() => _teamASelections.add(null));
            },
            onRemove: (i) {
              if (_teamASelections.length > 1) setState(() => _teamASelections.removeAt(i));
            },
          ),
          const Gap(20),
          _TeamPlayerFields(
            teamLabel: 'Team B (Max 5)',
            selections: _teamBSelections,
            onChange: (i, val) => setState(() => _teamBSelections[i] = val),
            onAdd: () {
              if (_teamBSelections.length < 5) setState(() => _teamBSelections.add(null));
            },
            onRemove: (i) {
              if (_teamBSelections.length > 1) setState(() => _teamBSelections.removeAt(i));
            },
          ),
        ],
      ],
    );
  }"""

    content = content[:start_idx] + new_method + content[end_idx+1:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Successfully replaced _buildPlayersStep")

if __name__ == "__main__":
    replace_block("lib/features/games/presentation/widgets/game_setup_sheet.dart")
