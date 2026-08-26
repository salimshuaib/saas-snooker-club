import os

path = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

old_cond = """            // ─── Winner Selection (Loser Pays non-multi round) ───
            if (!_isMultiRoundTP &&
                _session.gameType == GameType.standard &&
                _session.matchType == MatchType.loserPays) ...["""

new_cond = """            // ─── Winner Selection (Loser Pays non-multi round or Race game) ───
            if ((!_isMultiRoundTP && _session.gameType == GameType.standard && _session.matchType == MatchType.loserPays) ||
                (_session.gameType == GameType.race)) ...["""

c = c.replace(old_cond, new_cond)

old_check = """      if (!_isMultiRoundTP &&
          _session.gameType == GameType.standard &&
          _session.matchType == MatchType.loserPays &&
          _winnerId == null) {"""

new_check = """      if (((!_isMultiRoundTP && _session.gameType == GameType.standard && _session.matchType == MatchType.loserPays) || _session.gameType == GameType.race) &&
          _winnerId == null) {"""

c = c.replace(old_check, new_check)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
