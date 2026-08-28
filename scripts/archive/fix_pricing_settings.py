import os
import re

def fix_pricing_settings():
    path = 'lib/features/settings/domain/models/settings_models.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add fields
    old_fields = """  final double americanPoolHalfHour;
  final double americanPoolOneHour;

  const PricingSettings({"""
    new_fields = """  final double americanPoolHalfHour;
  final double americanPoolOneHour;
  
  final double snookerRacePerMinute;
  final double indianPoolRacePerMinute;
  final double americanPoolRacePerMinute;
  final double snookerRummyPerMinute;

  const PricingSettings({"""
    content = content.replace(old_fields, new_fields)

    # Add defaults
    old_defaults = """    this.americanPoolHalfHour = 150.00,
    this.americanPoolOneHour = 240.00,
  });"""
    new_defaults = """    this.americanPoolHalfHour = 150.00,
    this.americanPoolOneHour = 240.00,
    this.snookerRacePerMinute = 3.00,
    this.indianPoolRacePerMinute = 3.00,
    this.americanPoolRacePerMinute = 4.00,
    this.snookerRummyPerMinute = 4.00,
  });"""
    content = content.replace(old_defaults, new_defaults)

    # Add copyWith params
    old_copy_params = """    double? americanPoolHalfHour,
    double? americanPoolOneHour,
  }) {"""
    new_copy_params = """    double? americanPoolHalfHour,
    double? americanPoolOneHour,
    double? snookerRacePerMinute,
    double? indianPoolRacePerMinute,
    double? americanPoolRacePerMinute,
    double? snookerRummyPerMinute,
  }) {"""
    content = content.replace(old_copy_params, new_copy_params)

    # Add copyWith assignment
    old_copy_assign = """      americanPoolHalfHour: americanPoolHalfHour ?? this.americanPoolHalfHour,
      americanPoolOneHour: americanPoolOneHour ?? this.americanPoolOneHour,
    );"""
    new_copy_assign = """      americanPoolHalfHour: americanPoolHalfHour ?? this.americanPoolHalfHour,
      americanPoolOneHour: americanPoolOneHour ?? this.americanPoolOneHour,
      snookerRacePerMinute: snookerRacePerMinute ?? this.snookerRacePerMinute,
      indianPoolRacePerMinute: indianPoolRacePerMinute ?? this.indianPoolRacePerMinute,
      americanPoolRacePerMinute: americanPoolRacePerMinute ?? this.americanPoolRacePerMinute,
      snookerRummyPerMinute: snookerRummyPerMinute ?? this.snookerRummyPerMinute,
    );"""
    content = content.replace(old_copy_assign, new_copy_assign)

    # Add toMap
    old_tomap = """      'americanPoolHalfHour': americanPoolHalfHour,
      'americanPoolOneHour': americanPoolOneHour,
    };"""
    new_tomap = """      'americanPoolHalfHour': americanPoolHalfHour,
      'americanPoolOneHour': americanPoolOneHour,
      'snookerRacePerMinute': snookerRacePerMinute,
      'indianPoolRacePerMinute': indianPoolRacePerMinute,
      'americanPoolRacePerMinute': americanPoolRacePerMinute,
      'snookerRummyPerMinute': snookerRummyPerMinute,
    };"""
    content = content.replace(old_tomap, new_tomap)

    # Add fromMap
    old_frommap = """      americanPoolHalfHour: (map['americanPoolHalfHour'] as num?)?.toDouble() ?? 150.00,
      americanPoolOneHour: (map['americanPoolOneHour'] as num?)?.toDouble() ?? 240.00,
    );"""
    new_frommap = """      americanPoolHalfHour: (map['americanPoolHalfHour'] as num?)?.toDouble() ?? 150.00,
      americanPoolOneHour: (map['americanPoolOneHour'] as num?)?.toDouble() ?? 240.00,
      snookerRacePerMinute: (map['snookerRacePerMinute'] as num?)?.toDouble() ?? 3.00,
      indianPoolRacePerMinute: (map['indianPoolRacePerMinute'] as num?)?.toDouble() ?? 3.00,
      americanPoolRacePerMinute: (map['americanPoolRacePerMinute'] as num?)?.toDouble() ?? 4.00,
      snookerRummyPerMinute: (map['snookerRummyPerMinute'] as num?)?.toDouble() ?? 4.00,
    );"""
    content = content.replace(old_frommap, new_frommap)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_pricing_settings()
