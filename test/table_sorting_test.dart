import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

void main() {
  group('naturalTableCompare', () {
    test('sorts single digit numbers correctly', () {
      expect(naturalTableCompare('Arcade 1', 'Arcade 2'), lessThan(0));
      expect(naturalTableCompare('Arcade 2', 'Arcade 1'), greaterThan(0));
      expect(naturalTableCompare('Arcade 1', 'Arcade 1'), equals(0));
    });

    test('sorts multidigit numbers naturally without string 10 < 2 bug', () {
      final list = ['Arcade 10', 'Arcade 2', 'Arcade 1', 'Arcade 20', 'Arcade 3'];
      list.sort(naturalTableCompare);
      expect(list, ['Arcade 1', 'Arcade 2', 'Arcade 3', 'Arcade 10', 'Arcade 20']);
    });

    test('sorts complex game names with internal numbers correctly', () {
      final list = [
        'Tekken 7 Machine 10',
        'Tekken 7 Machine 2',
        'Tekken 7 Machine 1',
        'Pac-Man 2',
        'Pac-Man 1',
      ];
      list.sort(naturalTableCompare);
      expect(list, [
        'Pac-Man 1',
        'Pac-Man 2',
        'Tekken 7 Machine 1',
        'Tekken 7 Machine 2',
        'Tekken 7 Machine 10',
      ]);
    });
  });

  group('sortTables with Arcade Games and Multi-floor', () {
    test('does not allow timestamp creation order to scramble game serial numbers', () {
      // Simulate user creating Arcade 3 first (earlier timestamp), then Arcade 1, then Arcade 2
      final tables = [
        const TableModel(
          id: 'arc_3',
          name: 'Arcade 3',
          type: TableType.arcade,
          order: 1000, // created first
        ),
        const TableModel(
          id: 'arc_1',
          name: 'Arcade 1',
          type: TableType.arcade,
          order: 3000, // created last
        ),
        const TableModel(
          id: 'arc_2',
          name: 'Arcade 2',
          type: TableType.arcade,
          order: 2000, // created second
        ),
      ];

      final sorted = sortTables(tables);
      expect(sorted.map((t) => t.name).toList(), ['Arcade 1', 'Arcade 2', 'Arcade 3']);
    });

    test('groups multi-floor games cleanly by floor without interleaving', () {
      // Floor 1 has Arcade 1, 2, 3
      // Floor 2 has Arcade 1, 2
      // Created at interleaved timestamps
      final tables = [
        const TableModel(
          id: 'f1_arc_1',
          name: 'Arcade 1',
          type: TableType.arcade,
          floorId: 'floor_1',
          floorName: 'Floor 1',
          order: 100,
        ),
        const TableModel(
          id: 'f2_arc_1',
          name: 'Arcade 1',
          type: TableType.arcade,
          floorId: 'floor_2',
          floorName: 'Floor 2',
          order: 150,
        ),
        const TableModel(
          id: 'f1_arc_2',
          name: 'Arcade 2',
          type: TableType.arcade,
          floorId: 'floor_1',
          floorName: 'Floor 1',
          order: 200,
        ),
        const TableModel(
          id: 'f2_arc_2',
          name: 'Arcade 2',
          type: TableType.arcade,
          floorId: 'floor_2',
          floorName: 'Floor 2',
          order: 250,
        ),
        const TableModel(
          id: 'f1_arc_3',
          name: 'Arcade 3',
          type: TableType.arcade,
          floorId: 'floor_1',
          floorName: 'Floor 1',
          order: 300,
        ),
      ];

      final floorOrderMap = {'floor_1': 0, 'floor_2': 1};
      final sorted = sortTables(tables, floorOrderMap: floorOrderMap);

      expect(sorted.map((t) => '${t.name} (${t.floorName})').toList(), [
        'Arcade 1 (Floor 1)',
        'Arcade 2 (Floor 1)',
        'Arcade 3 (Floor 1)',
        'Arcade 1 (Floor 2)',
        'Arcade 2 (Floor 2)',
      ]);
    });

    test('preserves category order while sorting each category cleanly', () {
      final tables = [
        const TableModel(id: 'arc_2', name: 'Arcade 2', type: TableType.arcade),
        const TableModel(id: 'snk_2', name: 'Snooker 2', type: TableType.snooker),
        const TableModel(id: 'arc_1', name: 'Arcade 1', type: TableType.arcade),
        const TableModel(id: 'snk_1', name: 'Snooker 1', type: TableType.snooker),
        const TableModel(id: 'ps_1', name: 'PS5 1', type: TableType.ps5),
      ];

      final sorted = sortTables(tables);
      expect(sorted.map((t) => t.name).toList(), [
        'Snooker 1',
        'Snooker 2',
        'PS5 1',
        'Arcade 1',
        'Arcade 2',
      ]);
    });
  });
}
