import re

with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r'pricingSnapshot: pricingSnapshot,\s*gameSettingsSnapshot: appSettings\.game,\s*\);', content)
if match:
    clean_content = content[:match.end()] + '''

    setState(() => _isLoading = false);

    if (mounted) {
      if (widget.isCompletedGame) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BillingScreen(session: session),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    }

    Future.delayed(const Duration(milliseconds: 400), () async {
      try {
        for (final p in newProfilesToCreate) {
          await creditRepo.savePlayerProfile(p);
        }
        if (!widget.isCompletedGame) {
          await gamesRepo.startGame(session);
        }
      } catch (e) {
        debugPrint('Failed to process manual game setup in background: ');
      }
    });
  }
}
'''
    with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'w', encoding='utf-8') as f:
        f.write(clean_content)

with open('lib/features/games/presentation/widgets/repeat_game_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('widget.originalGame.id', 'widget.originalSession.id')

with open('lib/features/games/presentation/widgets/repeat_game_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed")
