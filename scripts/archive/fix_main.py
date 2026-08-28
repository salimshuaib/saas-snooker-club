path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\dashboard\presentation\screens\main_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('import \'package:snooker_club/features/authentication/providers/auth_providers.dart\';', 'import \'package:snooker_club/core/providers/club_scope_provider.dart\';')
content = content.replace('    ref.listen(clubIdProvider, (previous, next) {', '    ref.listen<String?>(clubIdProvider, (previous, next) {')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
