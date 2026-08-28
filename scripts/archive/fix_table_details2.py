import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''  Future<void> _handleEndGame(GameSession game, BuildContext context) async {
    if (game.billingType == BillingType.perFrame) {'''

replacement = '''  Future<void> _handleEndGame(GameSession game, BuildContext context) async {
    if (game.gameType == GameType.race) {
      if (mounted && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BillingScreen(session: game)),
        );
      }
      return;
    }

    if (game.billingType == BillingType.perFrame) {'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
