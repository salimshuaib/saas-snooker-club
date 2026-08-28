import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\widgets\repeat_game_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target1 = '''      if (_gameType == GameType.race) ...[
        const Gap(16),
        AppTextField(
          controller: TextEditingController(text: _targetPoints?.toString() ?? ''),
          label: 'Target Points', keyboardType: TextInputType.number,
          onChanged: (v) { final n = int.tryParse(v); if (n != null && n > 0) _targetPoints = n; },
        ),
      ],'''

content = content.replace(target1, '')

target2 = '''      if (_gameType == GameType.race) _buildSummaryRow('Target Points', _targetPoints?.toString() ?? '-'),'''

content = content.replace(target2, '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
