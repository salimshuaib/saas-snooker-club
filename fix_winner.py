import re

# 1. table_details_screen.dart
with open('lib/features/games/presentation/screens/table_details_screen.dart', 'r', encoding='utf-8') as f:
    table_code = f.read()

# For rounds inside table details
round_winner_search = r'''r\.winner == 'Friendly'
                                          \? 'Frame \$\{r\.roundNumber\} · \$\{\(r\.durationSeconds \?\? 0\) ~\/ 60\} mins\$\{\(r\.overtimeMinutes \?\? 0\) > 0 \? " \(\+\$\{r\.overtimeMinutes\}m OT\)" : ""\}'
                                          : 'Round \$\{r\.roundNumber\} · Winner: \$\{r\.winner \?\? "N/A"\}\$\{r\.loser != null \? " · Loser: \$\{r\.loser\}" : ""\}\$\{\(r\.overtimeMinutes \?\? 0\) > 0 \? " \(\+\$\{r\.overtimeMinutes\}m OT\)" : ""\}','''

# Replace the formatting inline for table_details_screen as well
def make_round_replace(session_var):
    return f'''r.winner == 'Friendly'
                                          ? 'Frame ${{r.roundNumber}} · ${{(r.durationSeconds ?? 0) ~/ 60}} mins${{(r.overtimeMinutes ?? 0) > 0 ? " (+${{r.overtimeMinutes}}m OT)" : ""}}'
                                          : 'Round ${{r.roundNumber}} · Winner: ${{r.winner == 'Team A' ? {session_var}.teamA.join(' & ') : r.winner == 'Team B' ? {session_var}.teamB.join(' & ') : (r.winner ?? "N/A")}}${{r.loser != null ? " · Loser: ${{r.loser == 'Team A' ? {session_var}.teamA.join(' & ') : r.loser == 'Team B' ? {session_var}.teamB.join(' & ') : r.loser}}" : ""}}${{(r.overtimeMinutes ?? 0) > 0 ? " (+${{r.overtimeMinutes}}m OT)" : ""}}','''

table_code = re.sub(round_winner_search, make_round_replace('game'), table_code)

with open('lib/features/games/presentation/screens/table_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(table_code)


# 2. bill_details_screen.dart
with open('lib/features/games/presentation/screens/bill_details_screen.dart', 'r', encoding='utf-8') as f:
    bill_code = f.read()

bill_round_search = r'''r\.winner == 'Friendly'
                              \? 'Frame \$\{r\.roundNumber\} · \$\{\(r\.durationSeconds \?\? 0\) ~\/ 60\} mins\$\{\(r\.overtimeMinutes \?\? 0\) > 0 \? " \(\+\$\{r\.overtimeMinutes\}m OT\)" : ""\}'
                              : 'Round \$\{r\.roundNumber\} · Winner: \$\{r\.winner \?\? "N/A"\}\$\{r\.loser != null \? " · Loser: \$\{r\.loser\}" : ""\}\$\{\(r\.overtimeMinutes \?\? 0\) > 0 \? " \(\+\$\{r\.overtimeMinutes\}m OT\)" : ""\}','''

bill_code = re.sub(bill_round_search, make_round_replace('session'), bill_code)

bill_code = bill_code.replace("value: session.winnerId ?? 'N/A'", "value: session.winnerDisplayName ?? 'N/A'")

loser_func = '''  String _getLoser(GameSession session) {
    if (session.winnerId == null) return 'N/A';
    if (session.mode == GameMode.team) {
      if (session.winnerId == 'Team A') {
        return 'Team B (${session.teamB.join(", ")})';
      } else {
        return 'Team A (${session.teamA.join(", ")})';
      }
    } else {
      final losers = session.allPlayers.where((p) => p != session.winnerId).toList();
      return losers.join(', ');
    }
  }'''

loser_replace = '''  String _getLoser(GameSession session) {
    return session.loserDisplayName ?? 'N/A';
  }'''

bill_code = bill_code.replace(loser_func, loser_replace)

with open('lib/features/games/presentation/screens/bill_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(bill_code)

print("Formatting updated.")
