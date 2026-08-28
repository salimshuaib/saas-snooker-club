path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('  final GameSettings? gameSettingsSnapshot;', '  final GameSettings? gameSettingsSnapshot;\n  final double? customPrice;')
content = content.replace('    this.gameSettingsSnapshot,\n  });', '    this.gameSettingsSnapshot,\n    this.customPrice,\n  });')
content = content.replace('    GameSettings? gameSettingsSnapshot,\n  }) {', '    GameSettings? gameSettingsSnapshot,\n    double? customPrice,\n  }) {')
content = content.replace('      gameSettingsSnapshot: gameSettingsSnapshot ?? this.gameSettingsSnapshot,\n    );', '      gameSettingsSnapshot: gameSettingsSnapshot ?? this.gameSettingsSnapshot,\n      customPrice: customPrice ?? this.customPrice,\n    );')
content = content.replace('''      'gameSettingsSnapshot': gameSettingsSnapshot?.toMap(),
    };''', '''      'gameSettingsSnapshot': gameSettingsSnapshot?.toMap(),
      'customPrice': customPrice,
    };''')
content = content.replace('''      gameSettingsSnapshot: map['gameSettingsSnapshot'] != null
          ? GameSettings.fromMap(map['gameSettingsSnapshot'])
          : null,
    );''', '''      gameSettingsSnapshot: map['gameSettingsSnapshot'] != null
          ? GameSettings.fromMap(map['gameSettingsSnapshot'])
          : null,
      customPrice: (map['customPrice'] as num?)?.toDouble(),
    );''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
