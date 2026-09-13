import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Try to find the exact line 284
lines = text.split('\n')
for i, line in enumerate(lines):
    if "return 'Confirm Payment" in line and "_finalTotal" in line:
        lines[i] = line.replace("_finalTotal", "_roundedTotal")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
