import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';

void main() {
  group('Onboarding Floor Setup Logic Tests', () {
    test('Floor list can be filtered and validated', () {
      final input = ['Ground Floor', '  ', '1st Floor', ''];
      final validFloors = input.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      expect(validFloors.length, 2);
      expect(validFloors[0], 'Ground Floor');
      expect(validFloors[1], '1st Floor');
    });

    test('Duplicate floor names are detected case-insensitively', () {
      final input = ['Ground Floor', 'ground floor'];
      final uniqueSet = input.map((e) => e.trim().toLowerCase()).toSet();

      expect(uniqueSet.length < input.length, isTrue);
    });

    test('Floor models are created with correct sequential orders', () {
      final floorNames = ['Ground Floor', '1st Floor', 'Rooftop Lounge'];
      final now = DateTime.now();

      final floors = List.generate(floorNames.length, (i) {
        return FloorModel(
          id: 'temp_$i',
          name: floorNames[i],
          order: i,
          createdAt: now,
        );
      });

      expect(floors[0].order, 0);
      expect(floors[1].order, 1);
      expect(floors[2].order, 2);
      expect(floors[2].name, 'Rooftop Lounge');
    });
  });
}
