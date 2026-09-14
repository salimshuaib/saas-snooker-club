import os

filepath = 'lib/features/games/presentation/screens/table_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

import re

# Remove _NoActiveGameCard completely
pattern = re.compile(r'class _NoActiveGameCard extends ConsumerWidget \{.*?\}\n\}\n', re.DOTALL)
text = pattern.sub('', text)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
