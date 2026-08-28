import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''  Future<void> _handleEndGame(GameSession game, BuildContext context) async {
    if (game.gameType == GameType.race) {
      if (!context.mounted) return;
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => _RoundCompletionDialog(game: game, isRace: true),
      );
      if (result == null || !mounted || !context.mounted) return;
      
      final winner = result['winner'] as String;
      
      final fakePoints = <String, int>{};
      fakePoints[winner] = 1;
      for (final p in game.allPlayers) {
        if (p != winner) fakePoints[p] = 0;
      }
      
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BillingScreen(session: game.copyWith(playerPoints: fakePoints)),
        ),
      );
      return;
    }

    if (game.billingType == BillingType.perFrame) {'''

replacement = '''  Future<void> _handleEndGame(GameSession game, BuildContext context) async {
    if (game.billingType == BillingType.perFrame) {'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
