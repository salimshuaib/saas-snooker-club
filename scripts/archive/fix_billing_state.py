import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''  bool _isProcessing = false;
  
  late TextEditingController _finalAmountController;'''

replacement = '''  bool _isProcessing = false;
  
  String? _raceSelectedWinnerTeam;
  String? _raceSelectedPayingPlayer;
  
  late TextEditingController _finalAmountController;'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
