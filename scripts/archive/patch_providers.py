path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\providers\games_providers.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content += '''
final resolvedOtherGamesProvider = Provider<List<OtherGameResource>>((ref) {
  return [];
});
'''
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
