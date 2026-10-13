import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';

void main() {
  group('Food Items & InventoryItem Models', () {
    test('Food item is correctly identified by isFood getter', () {
      final foodItem = InventoryItem(
        id: 'food_1',
        name: 'Veg Sandwich',
        category: 'Food',
        sellingPrice: 120.0,
        purchasePrice: 0.0,
        currentStock: 0,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final drinksItem = InventoryItem(
        id: 'drink_1',
        name: 'Coca Cola',
        category: 'Drinks',
        sellingPrice: 40.0,
        purchasePrice: 25.0,
        currentStock: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(foodItem.isFood, isTrue);
      expect(drinksItem.isFood, isFalse);
    });

    test('Food item availability determines isOutOfStock, not currentStock', () {
      final availableFood = InventoryItem(
        id: 'food_1',
        name: 'Chicken Burger',
        category: 'Food',
        sellingPrice: 180.0,
        purchasePrice: 0.0,
        currentStock: 0,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final unavailableFood = InventoryItem(
        id: 'food_2',
        name: 'French Fries',
        category: 'Food',
        sellingPrice: 90.0,
        purchasePrice: 0.0,
        currentStock: 0,
        isAvailable: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(availableFood.isOutOfStock, isFalse);
      expect(availableFood.isLowStock, isFalse);

      expect(unavailableFood.isOutOfStock, isTrue);
      expect(unavailableFood.isLowStock, isFalse);
    });

    test('Regular inventory item out of stock behavior remains standard', () {
      final inStockDrink = InventoryItem(
        id: 'drink_1',
        name: 'Red Bull',
        category: 'Drinks',
        sellingPrice: 120.0,
        currentStock: 12,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final outOfStockDrink = InventoryItem(
        id: 'drink_2',
        name: 'Water Bottle',
        category: 'Drinks',
        sellingPrice: 20.0,
        currentStock: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(inStockDrink.isOutOfStock, isFalse);
      expect(outOfStockDrink.isOutOfStock, isTrue);
    });

    test('Food item toMap and fromMap serialization roundtrip', () {
      final now = DateTime.now();
      final item = InventoryItem(
        id: 'food_3',
        name: 'Pasta Alfredo',
        category: 'Food',
        sellingPrice: 220.0,
        purchasePrice: 0.0,
        currentStock: 0,
        totalPurchased: 0,
        totalSold: 15,
        isActive: true,
        isAvailable: false,
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      expect(map['isAvailable'], isFalse);
      expect(map['category'], 'Food');
      expect(map['sellingPrice'], 220.0);
      expect(map['currentStock'], 0);

      final restored = InventoryItem.fromMap(item.id, map);
      expect(restored.id, item.id);
      expect(restored.name, 'Pasta Alfredo');
      expect(restored.isFood, isTrue);
      expect(restored.isAvailable, isFalse);
      expect(restored.isOutOfStock, isTrue);
    });

    test('copyWith updates isAvailable properly', () {
      final item = InventoryItem(
        id: 'food_4',
        name: 'Pizza',
        category: 'Food',
        sellingPrice: 250.0,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = item.copyWith(isAvailable: false);
      expect(updated.isAvailable, isFalse);
      expect(updated.isOutOfStock, isTrue);
    });
  });
}
