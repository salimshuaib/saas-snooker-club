import os

filepath = 'lib/features/games/presentation/widgets/table_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

start = text.find('class _ActiveGameInfo extends ConsumerStatefulWidget {')
if start != -1:
    text = text[:start]

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
