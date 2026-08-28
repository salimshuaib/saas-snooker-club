import re

with open('lib/features/games/domain/models/game_models.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace TableModel
old_tm = r"factory TableModel\.fromMap\(Map<String, dynamic> map\) \{.*?^\s*\}\s*\n\s*\}"
new_tm = """factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      type: TableType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TableType.snooker,
      ),
      status: TableStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      activeGameId: map['activeGameId']?.toString(),
      isActive: map['isActive'] == null ? true : (map['isActive'] as bool? ?? true),
      availableGameModes: (map['availableGameModes'] as List<dynamic>?)
              ?.map(
                (e) => GameType.values.firstWhere(
                  (gt) => gt.name == e?.toString(),
                  orElse: () => GameType.standard,
                ),
              )
              .toList() ??
          [GameType.standard, GameType.race, GameType.rummy],
      pricing: map['pricing'] is Map
          ? (map['pricing'] as Map).map(
              (k, v) => MapEntry(k.toString(), num.tryParse(v.toString())?.toDouble() ?? 0.0),
            )
          : {},
      order: num.tryParse(map['order']?.toString() ?? '')?.toInt() ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }
}"""

content = re.sub(old_tm, new_tm, content, flags=re.MULTILINE | re.DOTALL)

# Replace OtherGameResource
old_og = r"factory OtherGameResource\.fromMap\(Map<String, dynamic> map\) \{.*?^\s*\}\s*\n\s*\}"
new_og = """factory OtherGameResource.fromMap(Map<String, dynamic> map) {
    return OtherGameResource(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      category: OtherGameCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => OtherGameCategory.other,
      ),
      customCategoryName: map['customCategoryName']?.toString(),
      status: TableStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      activeGameId: map['activeGameId']?.toString(),
      isActive: map['isActive'] == null ? true : (map['isActive'] as bool? ?? true),
      pricing: map['pricing'] is Map
          ? (map['pricing'] as Map).map(
              (k, v) => MapEntry(k.toString(), num.tryParse(v.toString())?.toDouble() ?? 0.0),
            )
          : {},
      order: num.tryParse(map['order']?.toString() ?? '')?.toInt() ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }
}"""

content = re.sub(old_og, new_og, content, flags=re.MULTILINE | re.DOTALL)

with open('lib/features/games/domain/models/game_models.dart', 'w', encoding='utf-8') as f:
    f.write(content)

