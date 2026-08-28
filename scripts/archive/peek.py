import re

with open('lib/features/games/presentation/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# I need to review the entire _calculatedLiabilities getter first to see what it does.
print(content[content.find('Map<String, double> get _calculatedLiabilities {'):content.find('  double get _gameCharge {')])
