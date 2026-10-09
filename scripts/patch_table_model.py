import sys
import re

path = 'lib/features/games/domain/models/game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add to fields
content = content.replace('  final bool allowCustomPrice;', '  final bool allowCustomPrice;\n  final bool isTimeNotSure;')

# Add to constructor
content = content.replace('    this.allowCustomPrice = false,\n  });', '    this.allowCustomPrice = false,\n    this.isTimeNotSure = false,\n  });')

# Add to copyWith params
content = content.replace('    bool? allowCustomPrice,\n  }) {', '    bool? allowCustomPrice,\n    bool? isTimeNotSure,\n  }) {')

# Add to copyWith constructor
content = content.replace('      allowCustomPrice: allowCustomPrice ?? this.allowCustomPrice,\n    );', '      allowCustomPrice: allowCustomPrice ?? this.allowCustomPrice,\n      isTimeNotSure: isTimeNotSure ?? this.isTimeNotSure,\n    );')

# Add to toMap
content = content.replace("      'allowCustomPrice': allowCustomPrice,\n    };", "      'allowCustomPrice': allowCustomPrice,\n      'isTimeNotSure': isTimeNotSure,\n    };")

# Add to fromMap
content = content.replace("      allowCustomPrice: map['allowCustomPrice'] ?? false,\n    );", "      allowCustomPrice: map['allowCustomPrice'] ?? false,\n      isTimeNotSure: map['isTimeNotSure'] ?? false,\n    );")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched TableModel in game_models.dart')
