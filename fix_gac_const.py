import sys

with open('lib/features/games/presentation/widgets/game_activity_card.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('const BorderSide', 'BorderSide')
text = text.replace('const BoxDecoration', 'BoxDecoration')

with open('lib/features/games/presentation/widgets/game_activity_card.dart', 'w', encoding='utf-8') as f:
    f.write(text)
