import 'package:snooker_club/features/games/domain/models/game_models.dart';

/// Centralized configuration for physical table mappings and permanent game assignments.
/// This single source of truth ensures table names and assigned game types are never hardcoded across modules.
class TablesConfig {
  TablesConfig._();

  static const List<TableModel> defaultTables = [
    TableModel(id: 'snooker_1', name: 'Snooker Table 1', type: TableType.snooker),
    TableModel(id: 'snooker_2', name: 'Snooker Table 2', type: TableType.snooker),
    TableModel(id: 'snooker_3', name: 'Snooker Table 3', type: TableType.snooker),
    TableModel(id: 'indian_pool_1', name: 'Indian Pool Table 1', type: TableType.indianPool),
    TableModel(id: 'indian_pool_2', name: 'Indian Pool Table 2', type: TableType.indianPool),
    TableModel(id: 'american_pool_1', name: 'American Pool Table 1', type: TableType.americanPool),
  ];
}
