import sys
import re

path = 'lib/features/games/domain/models/game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add to fields
content = content.replace('  final double? customPrice;', '  final double? customPrice;\n  final bool isTimeNotSure;')

# Add to constructor
content = content.replace('    this.customPrice,\n  });', '    this.customPrice,\n    this.isTimeNotSure = false,\n  });')

# Add to copyWith params
content = content.replace('    double? customPrice,\n  }) {', '    double? customPrice,\n    bool? isTimeNotSure,\n  }) {')

# Add to copyWith constructor
content = content.replace('      customPrice: customPrice ?? this.customPrice,\n    );', '      customPrice: customPrice ?? this.customPrice,\n      isTimeNotSure: isTimeNotSure ?? this.isTimeNotSure,\n    );')

# Add to toMap
content = content.replace("      'customPrice': customPrice,\n    };", "      'customPrice': customPrice,\n      'isTimeNotSure': isTimeNotSure,\n    };")

# Add to fromMap
content = content.replace("      customPrice: (map['customPrice'] as num?)?.toDouble(),\n    );", "      customPrice: (map['customPrice'] as num?)?.toDouble(),\n      isTimeNotSure: map['isTimeNotSure'] ?? false,\n    );")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched game_models.dart')
