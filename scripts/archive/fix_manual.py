import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\manual_game_setup_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target1 = '''        // TARGET POINTS (RACE)
        if (_gameType == GameType.race) ...[
          const Gap(16),
          AppTextField(
            controller: TextEditingController(text: _targetPoints?.toString() ?? ''),
            label: 'Target Points',
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0) _targetPoints = n;
            },
          ),
        ],'''

content = content.replace(target1, '')

target2 = '''    if (_step == 3 && _gameType == GameType.race && (_targetPoints == null || _targetPoints! <= 0)) {
      _showError('Please enter valid target points.');
      return;
    }'''

content = content.replace(target2, '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
