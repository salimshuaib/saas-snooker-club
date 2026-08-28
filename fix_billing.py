import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''      } else if (_session.gameType == GameType.race) {
        if (_session.mode == GameMode.solo) {
          // Race Solo: Loser (lowest points) pays 100%
          String? loser;
          int lowestPoints = 999999;
          for (final p in _session.allPlayers) {
            final pts = _session.playerPoints?[p] ?? 0;
            if (pts < lowestPoints) {
              lowestPoints = pts;
              loser = p;
            }
          }
          if (loser != null) liabilities[loser] = totalToSplit;
        } else {
          // Race Team: Losing team (lowest points) splits bill
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
      }'''

replacement = '''      } else if (_session.gameType == GameType.race) {
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
      }'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
