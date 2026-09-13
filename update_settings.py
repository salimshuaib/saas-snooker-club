import os

filepath = 'lib/features/settings/domain/models/settings_models.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace GameSettings definition
old_def = """class GameSettings {
  final int frameGracePeriodMinutes;
  final bool enableOvertimeBilling;
  final bool allowPauseResume;
  final int maxPlayersPerTeam;

  const GameSettings({
    this.frameGracePeriodMinutes = 20,
    this.enableOvertimeBilling = true,
    this.allowPauseResume = true,
    this.maxPlayersPerTeam = 3,
  });"""
new_def = """class GameSettings {
  final int frameGracePeriodMinutes; // Fallback / Global
  final int indianPoolGracePeriodMinutes;
  final int americanPoolGracePeriodMinutes;
  final bool enableOvertimeBilling;
  final bool allowPauseResume;
  final int maxPlayersPerTeam;

  const GameSettings({
    this.frameGracePeriodMinutes = 20,
    this.indianPoolGracePeriodMinutes = 20,
    this.americanPoolGracePeriodMinutes = 20,
    this.enableOvertimeBilling = true,
    this.allowPauseResume = true,
    this.maxPlayersPerTeam = 3,
  });"""
text = text.replace(old_def, new_def)

# Replace copyWith
old_copy = """  GameSettings copyWith({
    int? frameGracePeriodMinutes,
    bool? enableOvertimeBilling,
    bool? allowPauseResume,
    int? maxPlayersPerTeam,
  }) {
    return GameSettings(
      frameGracePeriodMinutes:
          frameGracePeriodMinutes ?? this.frameGracePeriodMinutes,
      enableOvertimeBilling:
          enableOvertimeBilling ?? this.enableOvertimeBilling,
      allowPauseResume: allowPauseResume ?? this.allowPauseResume,
      maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
    );
  }"""
new_copy = """  GameSettings copyWith({
    int? frameGracePeriodMinutes,
    int? indianPoolGracePeriodMinutes,
    int? americanPoolGracePeriodMinutes,
    bool? enableOvertimeBilling,
    bool? allowPauseResume,
    int? maxPlayersPerTeam,
  }) {
    return GameSettings(
      frameGracePeriodMinutes: frameGracePeriodMinutes ?? this.frameGracePeriodMinutes,
      indianPoolGracePeriodMinutes: indianPoolGracePeriodMinutes ?? this.indianPoolGracePeriodMinutes,
      americanPoolGracePeriodMinutes: americanPoolGracePeriodMinutes ?? this.americanPoolGracePeriodMinutes,
      enableOvertimeBilling: enableOvertimeBilling ?? this.enableOvertimeBilling,
      allowPauseResume: allowPauseResume ?? this.allowPauseResume,
      maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
    );
  }"""
text = text.replace(old_copy, new_copy)

# Replace toMap
old_tomap = """  Map<String, dynamic> toMap() {
    return {
      'frameGracePeriodMinutes': frameGracePeriodMinutes,
      'enableOvertimeBilling': enableOvertimeBilling,
      'allowPauseResume': allowPauseResume,
      'maxPlayersPerTeam': maxPlayersPerTeam,
    };
  }"""
new_tomap = """  Map<String, dynamic> toMap() {
    return {
      'frameGracePeriodMinutes': frameGracePeriodMinutes,
      'indianPoolGracePeriodMinutes': indianPoolGracePeriodMinutes,
      'americanPoolGracePeriodMinutes': americanPoolGracePeriodMinutes,
      'enableOvertimeBilling': enableOvertimeBilling,
      'allowPauseResume': allowPauseResume,
      'maxPlayersPerTeam': maxPlayersPerTeam,
    };
  }"""
text = text.replace(old_tomap, new_tomap)

# Replace fromMap
old_frommap = """  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      frameGracePeriodMinutes:
          (map['frameGracePeriodMinutes'] as num?)?.toInt() ?? 20,
      enableOvertimeBilling: map['enableOvertimeBilling'] as bool? ?? true,
      allowPauseResume: map['allowPauseResume'] as bool? ?? true,
      maxPlayersPerTeam: (map['maxPlayersPerTeam'] as num?)?.toInt() ?? 3,
    );
  }"""
new_frommap = """  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      frameGracePeriodMinutes: (map['frameGracePeriodMinutes'] as num?)?.toInt() ?? 20,
      indianPoolGracePeriodMinutes: (map['indianPoolGracePeriodMinutes'] as num?)?.toInt() ?? 20,
      americanPoolGracePeriodMinutes: (map['americanPoolGracePeriodMinutes'] as num?)?.toInt() ?? 20,
      enableOvertimeBilling: map['enableOvertimeBilling'] as bool? ?? true,
      allowPauseResume: map['allowPauseResume'] as bool? ?? true,
      maxPlayersPerTeam: (map['maxPlayersPerTeam'] as num?)?.toInt() ?? 3,
    );
  }"""
text = text.replace(old_frommap, new_frommap)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
