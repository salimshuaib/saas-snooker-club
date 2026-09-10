import re

path = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(path, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Replace any sequence of weird characters that are used as Rupee symbol
# The corrupted string is 'Ã¢â€šÂ¹' or 'â,¹'
content = re.sub(r'[Ãâ][^0-9a-zA-Z\s]{1,5}', '₹', content)
# Also fix the divider lines
content = re.sub(r'â”€â”€', '──', content)
content = re.sub(r'// [^A-Za-z0-9\s]+ (.*?) [^A-Za-z0-9\s]+', r'// ── \1 ──', content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated")
