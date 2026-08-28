path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\models\game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('  final Map<String, double>? dynamicPricingSnapshot;', '  final Map<String, double>? dynamicPricingSnapshot;\n  final double? customPrice;')
content = content.replace('    this.dynamicPricingSnapshot,\n  });', '    this.dynamicPricingSnapshot,\n    this.customPrice,\n  });')
content = content.replace('    Map<String, double>? dynamicPricingSnapshot,\n  }) {', '    Map<String, double>? dynamicPricingSnapshot,\n    double? customPrice,\n  }) {')
content = content.replace('          dynamicPricingSnapshot ?? this.dynamicPricingSnapshot,\n    );', '          dynamicPricingSnapshot ?? this.dynamicPricingSnapshot,\n      customPrice: customPrice ?? this.customPrice,\n    );')
content = content.replace('''      'dynamicPricingSnapshot': dynamicPricingSnapshot,\n    };''', '''      'dynamicPricingSnapshot': dynamicPricingSnapshot,\n      'customPrice': customPrice,\n    };''')
content = content.replace('''      dynamicPricingSnapshot: map['dynamicPricingSnapshot'] != null
          ? (map['dynamicPricingSnapshot'] as Map).map(
              (key, value) => MapEntry(key as String, (value as num).toDouble()),
            )
          : null,
    );
  }''', '''      dynamicPricingSnapshot: map['dynamicPricingSnapshot'] != null
          ? (map['dynamicPricingSnapshot'] as Map).map(
              (key, value) => MapEntry(key as String, (value as num).toDouble()),
            )
          : null,
      customPrice: (map['customPrice'] as num?)?.toDouble(),
    );
  }''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
