path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('    required this.status,\n    this.activeGameId,\n    this.order = 0,\n  });', '    this.status = TableStatus.available,\n    this.activeGameId,\n    this.order = 0,\n  });')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
