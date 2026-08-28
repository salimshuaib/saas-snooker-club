import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    _playerPaymentMethods = {
      for (final p in _session.allPlayers) p: PaymentMethod.cash,
    };
    // Initialization of _customLiabilities will happen in didChangeDependencies'''

replacement = '''    _playerPaymentMethods = {
      for (final p in _session.allPlayers) p: PaymentMethod.cash,
    };
    if (_session.gameType == GameType.race) {
      if (_session.mode == GameMode.team) {
        _raceSelectedWinnerTeam = 'Team A';
      } else if (_session.allPlayers.isNotEmpty) {
        // By default, the first player pays
        _raceSelectedPayingPlayer = _session.allPlayers.first;
      }
    }
    // Initialization of _customLiabilities will happen in didChangeDependencies'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
