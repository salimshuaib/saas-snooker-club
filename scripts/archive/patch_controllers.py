path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\presentation\widgets\pricing_edit_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

new_controllers = '''  late final TextEditingController _americanRaceMinController;

  // Other Games
  late final TextEditingController _ps530mController;
  late final TextEditingController _ps51hController;
  late final TextEditingController _pc30mController;
  late final TextEditingController _pc1hController;
  late final TextEditingController _carrom30mController;
  late final TextEditingController _carrom1hController;
  late final TextEditingController _foosball30mController;
  late final TextEditingController _foosball1hController;
  late final TextEditingController _chess30mController;
  late final TextEditingController _chess1hController;'''
content = content.replace('  late final TextEditingController _americanRaceMinController;', new_controllers)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
