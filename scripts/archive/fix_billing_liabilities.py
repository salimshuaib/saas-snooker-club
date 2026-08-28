import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    } else if (_session.gameType == GameType.race) {
      if (_session.mode == GameMode.solo) {
        // Race Solo: All losers (0 points) split the bill
        final losers = _session.allPlayers.where((p) => (_session.playerPoints?[p] ?? 0) == 0).toList();
        if (losers.isNotEmpty) {
          final split = totalToSplit / losers.length;
          for (final p in losers) liabilities[p] = split;
        }
      } else {
        // Race Team: Losing team (0 points) splits bill
        final teamAPts = _session.playerPoints?['Team A'] ?? 0;
        final teamBPts = _session.playerPoints?['Team B'] ?? 0;
        final losingTeam = teamAPts <= teamBPts
            ? _session.teamA
            : _session.teamB;
        if (losingTeam.isNotEmpty) {
          final split = totalToSplit / losingTeam.length;
          for (final p in losingTeam) {
            liabilities[p] = split;
          }
        }
      }
    } else {'''

replacement = '''    } else if (_session.gameType == GameType.race) {
      if (_session.mode == GameMode.solo) {
        if (_raceSelectedPayingPlayer != null) {
          liabilities[_raceSelectedPayingPlayer!] = totalToSplit;
        }
      } else {
        if (_raceSelectedWinnerTeam != null) {
          final losingTeam = _raceSelectedWinnerTeam == 'Team A' ? _session.teamB : _session.teamA;
          if (losingTeam.isNotEmpty) {
            final split = totalToSplit / losingTeam.length;
            for (final p in losingTeam) {
              liabilities[p] = split;
            }
          }
        }
      }
    } else {'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
