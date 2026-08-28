path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add order to TableModel
content = content.replace('  final double? customPrice;', '  final double? customPrice;\n  final int order;')
content = content.replace('    this.customPrice,\n  });', '    this.customPrice,\n    this.order = 0,\n  });')
content = content.replace('    double? customPrice,\n  }) {', '    double? customPrice,\n    int? order,\n  }) {')
content = content.replace('      customPrice: customPrice ?? this.customPrice,\n    );', '      customPrice: customPrice ?? this.customPrice,\n      order: order ?? this.order,\n    );')
content = content.replace(\"      'customPrice': customPrice,\n    };\", \"      'customPrice': customPrice,\n      'order': order,\n    };\")
content = content.replace(\"      customPrice: (map['customPrice'] as num?)?.toDouble(),\n    );\", \"      customPrice: (map['customPrice'] as num?)?.toDouble(),\n      order: map['order'] ?? 0,\n    );\")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
