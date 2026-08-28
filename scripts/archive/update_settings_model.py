path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\domain\models\settings_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

new_fields = '''    final double snookerRummyPerMinute;
  
    // Other Games
    final double ps5HalfHour;
    final double ps5OneHour;
    final double pcHalfHour;
    final double pcOneHour;
    final double carromHalfHour;
    final double carromOneHour;
    final double foosballHalfHour;
    final double foosballOneHour;
    final double chessHalfHour;
    final double chessOneHour;'''
content = content.replace('    final double snookerRummyPerMinute;', new_fields)

new_constructor = '''      this.snookerRummyPerMinute = 4.00,
      this.ps5HalfHour = 100.00,
      this.ps5OneHour = 200.00,
      this.pcHalfHour = 80.00,
      this.pcOneHour = 150.00,
      this.carromHalfHour = 50.00,
      this.carromOneHour = 90.00,
      this.foosballHalfHour = 60.00,
      this.foosballOneHour = 100.00,
      this.chessHalfHour = 30.00,
      this.chessOneHour = 50.00,
    });'''
content = content.replace('''      this.snookerRummyPerMinute = 4.00,
    });''', new_constructor)

new_copy_with_args = '''    double? snookerRummyPerMinute,
    double? ps5HalfHour,
    double? ps5OneHour,
    double? pcHalfHour,
    double? pcOneHour,
    double? carromHalfHour,
    double? carromOneHour,
    double? foosballHalfHour,
    double? foosballOneHour,
    double? chessHalfHour,
    double? chessOneHour,
  }) {'''
content = content.replace('''    double? snookerRummyPerMinute,
  }) {''', new_copy_with_args)

new_copy_with_body = '''      snookerRummyPerMinute: snookerRummyPerMinute ?? this.snookerRummyPerMinute,
      ps5HalfHour: ps5HalfHour ?? this.ps5HalfHour,
      ps5OneHour: ps5OneHour ?? this.ps5OneHour,
      pcHalfHour: pcHalfHour ?? this.pcHalfHour,
      pcOneHour: pcOneHour ?? this.pcOneHour,
      carromHalfHour: carromHalfHour ?? this.carromHalfHour,
      carromOneHour: carromOneHour ?? this.carromOneHour,
      foosballHalfHour: foosballHalfHour ?? this.foosballHalfHour,
      foosballOneHour: foosballOneHour ?? this.foosballOneHour,
      chessHalfHour: chessHalfHour ?? this.chessHalfHour,
      chessOneHour: chessOneHour ?? this.chessOneHour,
    );'''
content = content.replace('''      snookerRummyPerMinute: snookerRummyPerMinute ?? this.snookerRummyPerMinute,
    );''', new_copy_with_body)

new_tomap = '''      'snookerRummyPerMinute': snookerRummyPerMinute,
      'ps5HalfHour': ps5HalfHour,
      'ps5OneHour': ps5OneHour,
      'pcHalfHour': pcHalfHour,
      'pcOneHour': pcOneHour,
      'carromHalfHour': carromHalfHour,
      'carromOneHour': carromOneHour,
      'foosballHalfHour': foosballHalfHour,
      'foosballOneHour': foosballOneHour,
      'chessHalfHour': chessHalfHour,
      'chessOneHour': chessOneHour,
    };'''
content = content.replace('''      'snookerRummyPerMinute': snookerRummyPerMinute,
    };''', new_tomap)

new_frommap = '''      snookerRummyPerMinute: (map['snookerRummyPerMinute'] as num?)?.toDouble() ?? 4.00,
      ps5HalfHour: (map['ps5HalfHour'] as num?)?.toDouble() ?? 100.00,
      ps5OneHour: (map['ps5OneHour'] as num?)?.toDouble() ?? 200.00,
      pcHalfHour: (map['pcHalfHour'] as num?)?.toDouble() ?? 80.00,
      pcOneHour: (map['pcOneHour'] as num?)?.toDouble() ?? 150.00,
      carromHalfHour: (map['carromHalfHour'] as num?)?.toDouble() ?? 50.00,
      carromOneHour: (map['carromOneHour'] as num?)?.toDouble() ?? 90.00,
      foosballHalfHour: (map['foosballHalfHour'] as num?)?.toDouble() ?? 60.00,
      foosballOneHour: (map['foosballOneHour'] as num?)?.toDouble() ?? 100.00,
      chessHalfHour: (map['chessHalfHour'] as num?)?.toDouble() ?? 30.00,
      chessOneHour: (map['chessOneHour'] as num?)?.toDouble() ?? 50.00,
    );'''
content = content.replace('''      snookerRummyPerMinute: (map['snookerRummyPerMinute'] as num?)?.toDouble() ?? 4.00,
    );''', new_frommap)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
