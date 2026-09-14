import os

filepath = 'lib/features/games/presentation/screens/games_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace AppLocalizations.of(context)!.games with "Game History" (hardcoded for now to save time, or we can use the locale, but the user specifically said "Game History")
# The string is `title: Text(AppLocalizations.of(context)!.games)`
text = text.replace('title: Text(AppLocalizations.of(context)!.games)', "title: const Text('Game History')")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
