path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\data\settings_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content += '''
  Future<void> migrateTablesPricing() async {}
'''
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
