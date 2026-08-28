path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\data\games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('.orderBy(\'order\')', '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
