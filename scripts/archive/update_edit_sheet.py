path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\presentation\widgets\pricing_edit_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Add controllers
new_controllers = '''  late TextEditingController _americanRaceMinController;

  // Other Games
  late TextEditingController _ps530mController;
  late TextEditingController _ps51hController;
  late TextEditingController _pc30mController;
  late TextEditingController _pc1hController;
  late TextEditingController _carrom30mController;
  late TextEditingController _carrom1hController;
  late TextEditingController _foosball30mController;
  late TextEditingController _foosball1hController;
  late TextEditingController _chess30mController;
  late TextEditingController _chess1hController;'''
content = content.replace('  late TextEditingController _americanRaceMinController;', new_controllers)

# Init state
new_init = '''    _americanRaceMinController = TextEditingController(text: p.americanPoolRacePerMinute.toStringAsFixed(2));

    _ps530mController = TextEditingController(text: p.ps5HalfHour.toStringAsFixed(2));
    _ps51hController = TextEditingController(text: p.ps5OneHour.toStringAsFixed(2));
    _pc30mController = TextEditingController(text: p.pcHalfHour.toStringAsFixed(2));
    _pc1hController = TextEditingController(text: p.pcOneHour.toStringAsFixed(2));
    _carrom30mController = TextEditingController(text: p.carromHalfHour.toStringAsFixed(2));
    _carrom1hController = TextEditingController(text: p.carromOneHour.toStringAsFixed(2));
    _foosball30mController = TextEditingController(text: p.foosballHalfHour.toStringAsFixed(2));
    _foosball1hController = TextEditingController(text: p.foosballOneHour.toStringAsFixed(2));
    _chess30mController = TextEditingController(text: p.chessHalfHour.toStringAsFixed(2));
    _chess1hController = TextEditingController(text: p.chessOneHour.toStringAsFixed(2));'''
content = content.replace('    _americanRaceMinController = TextEditingController(text: p.americanPoolRacePerMinute.toStringAsFixed(2));', new_init)

# Dispose
new_dispose = '''    _americanRaceMinController.dispose();

    _ps530mController.dispose();
    _ps51hController.dispose();
    _pc30mController.dispose();
    _pc1hController.dispose();
    _carrom30mController.dispose();
    _carrom1hController.dispose();
    _foosball30mController.dispose();
    _foosball1hController.dispose();
    _chess30mController.dispose();
    _chess1hController.dispose();'''
content = content.replace('    _americanRaceMinController.dispose();', new_dispose)

# Updated object
new_updated = '''        americanPoolRacePerMinute: double.parse(_americanRaceMinController.text.trim()),
        ps5HalfHour: double.parse(_ps530mController.text.trim()),
        ps5OneHour: double.parse(_ps51hController.text.trim()),
        pcHalfHour: double.parse(_pc30mController.text.trim()),
        pcOneHour: double.parse(_pc1hController.text.trim()),
        carromHalfHour: double.parse(_carrom30mController.text.trim()),
        carromOneHour: double.parse(_carrom1hController.text.trim()),
        foosballHalfHour: double.parse(_foosball30mController.text.trim()),
        foosballOneHour: double.parse(_foosball1hController.text.trim()),
        chessHalfHour: double.parse(_chess30mController.text.trim()),
        chessOneHour: double.parse(_chess1hController.text.trim()),'''
content = content.replace('        americanPoolRacePerMinute: double.parse(_americanRaceMinController.text.trim()),', new_updated)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
