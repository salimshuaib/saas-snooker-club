path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'activeGameId': activeGameId,
    };
  }''', '''  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'activeGameId': activeGameId,
      'order': order,
    };
  }''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
