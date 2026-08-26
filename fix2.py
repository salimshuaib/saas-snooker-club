import re

with open('lib/features/games/presentation/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Hide Winner Selection for non-standard games
winner_ui_old = "if (!_isMultiRoundTP && _session.matchType == MatchType.loserPays) ...["
winner_ui_new = "if (!_isMultiRoundTP && _session.gameType == GameType.standard && _session.matchType == MatchType.loserPays) ...["
content = content.replace(winner_ui_old, winner_ui_new)

# Fix 2: Skip winner validation for non-standard games
winner_val_old = "if (!_isMultiRoundTP && _session.matchType == MatchType.loserPays && _winnerId == null) {"
winner_val_new = "if (!_isMultiRoundTP && _session.gameType == GameType.standard && _session.matchType == MatchType.loserPays && _winnerId == null) {"
content = content.replace(winner_val_old, winner_val_new)

# Fix 3: Also skip the single-payer validation for non-standard games
payer_val_old = "if (!_isMultiRoundTP && _paymentMethod == PaymentMethod.credit && _PlayerProfileName == null) {"
payer_val_new = "if (!_isMultiRoundTP && _session.gameType == GameType.standard && _paymentMethod == PaymentMethod.credit && _PlayerProfileName == null) {"
content = content.replace(payer_val_old, payer_val_new)

with open('lib/features/games/presentation/screens/billing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
