import sys

path = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("if (club?.clubName == 'Only We Have A Club' || club?.slug == 'cuezone')", "if (clubAsync.value?.clubName == 'Only We Have A Club' || clubAsync.value?.slug == 'cuezone')")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched dashboard_screen.dart with clubAsync.value')
