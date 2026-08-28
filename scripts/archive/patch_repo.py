path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\data\games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content += '''
  Stream<List<OtherGameResource>> watchOtherGames() {
    return Stream.value([]);
  }

  Stream<List<OtherGameResource>> watchAllOtherGamesManagement() {
    return Stream.value([]);
  }

  Future<void> addOtherGame(OtherGameResource resource) async {}
  Future<void> updateOtherGame(OtherGameResource resource) async {}
'''
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
