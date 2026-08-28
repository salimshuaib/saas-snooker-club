path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\dashboard\presentation\screens\main_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

if 'import \'package:snooker_club/features/authentication/providers/auth_providers.dart\';' not in content:
    content = 'import \'package:snooker_club/features/authentication/providers/auth_providers.dart\';\n' + content

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
