path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''enum TableType {
  snooker,
  indianPool,
  americanPool;''', '''enum TableType {
  snooker,
  indianPool,
  americanPool,
  ps5,
  pc,
  carrom,
  foosball,
  chess;''')

content = content.replace('''    switch (this) {
      case TableType.snooker:
        return 'Snooker';
      case TableType.indianPool:
        return 'Indian Pool';
      case TableType.americanPool:
        return 'American Pool';
    }''', '''    switch (this) {
      case TableType.snooker:
        return 'Snooker';
      case TableType.indianPool:
        return 'Indian Pool';
      case TableType.americanPool:
        return 'American Pool';
      case TableType.ps5:
        return 'PS5';
      case TableType.pc:
        return 'PC';
      case TableType.carrom:
        return 'Carrom';
      case TableType.foosball:
        return 'Foosball';
      case TableType.chess:
        return 'Chess';
    }''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
