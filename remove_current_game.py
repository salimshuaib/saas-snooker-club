import re

filepath = 'lib/features/games/presentation/screens/table_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Pattern to find the Current Game Section and remove it
pattern = re.compile(r'// ── Current Game Section ──.*?// ── History Section ──', re.DOTALL)
text = pattern.sub('// ── History Section ──', text)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
