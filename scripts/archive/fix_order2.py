path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add order to TableModel
content = content.replace('  final TableStatus status;\n  final String? activeGameId;', '  final TableStatus status;\n  final String? activeGameId;\n  final int order;')
content = content.replace('    required this.status,\n    this.activeGameId,\n  });', '    required this.status,\n    this.activeGameId,\n    this.order = 0,\n  });')
content = content.replace('    TableStatus? status,\n    String? activeGameId,\n  }) {', '    TableStatus? status,\n    String? activeGameId,\n    int? order,\n  }) {')
content = content.replace('      activeGameId: activeGameId ?? this.activeGameId,\n    );', '      activeGameId: activeGameId ?? this.activeGameId,\n      order: order ?? this.order,\n    );')
content = content.replace('''      'status': status.name,
      'activeGameId': activeGameId,
    };''', '''      'status': status.name,
      'activeGameId': activeGameId,
      'order': order,
    };''')
content = content.replace('''      status: TableStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      activeGameId: map['activeGameId'] as String?,
    );''', '''      status: TableStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      activeGameId: map['activeGameId'] as String?,
      order: map['order'] as int? ?? 0,
    );''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
