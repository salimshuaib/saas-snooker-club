import os

path = 'lib/l10n/app_en.arb'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('Snooker Club', 'Sharma Billiards')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
