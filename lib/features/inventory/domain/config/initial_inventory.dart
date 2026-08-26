import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';

/// Static initial product configuration extracted from the original Games catalogue.
/// Used exclusively by the Inventory seeder to populate the master Firestore database
/// with dummy stock values for initial development.
class InitialInventory {
  InitialInventory._();

  static const String categoryDrinks = 'Drinks';
  static const String categoryCigarettes = 'Cigarettes';

  static List<InventoryItem> get items => [
        // ── Drinks ──
        _item('d01', 'Real Cranberry', categoryDrinks, 30.0),
        _item('d02', 'Water Bottle (Large)', categoryDrinks, 20.0),
        _item('d03', 'Water Bottle (Small)', categoryDrinks, 10.0),
        _item('d04', 'Fanta (Small)', categoryDrinks, 30.0),
        _item('d05', 'Diet Coke', categoryDrinks, 30.0),
        _item('d06', 'Coca-Cola', categoryDrinks, 30.0),
        _item('d07', 'Sprite Can', categoryDrinks, 30.0),
        _item('d08', 'Campa Energy', categoryDrinks, 30.0),
        _item('d09', 'Non Stop Energy Drink', categoryDrinks, 60.0),
        _item('d10', 'Hell Energy Drink', categoryDrinks, 80.0),
        _item('d11', 'Red Bull', categoryDrinks, 130.0),
        _item('d12', 'Amul Coffee', categoryDrinks, 30.0),

        // ── Cigarettes (₹15) ──
        _item('c01', 'Chhoti Advance', categoryCigarettes, 15.0),
        _item('c02', 'Chhoti Gold Flake', categoryCigarettes, 15.0),
        _item('c03', 'Mond', categoryCigarettes, 15.0),
        _item('c04', 'Sift', categoryCigarettes, 15.0),

        // ── Cigarettes (₹20) ──
        _item('c05', 'Define Pan', categoryCigarettes, 20.0),
        _item('c06', 'Connect', categoryCigarettes, 20.0),
        _item('c07', 'Normal Define', categoryCigarettes, 20.0),

        // ── Cigarettes (₹25) ──
        _item('c08', 'Badi Advance', categoryCigarettes, 25.0),
        _item('c09', 'Badi Gold Flake', categoryCigarettes, 25.0),
        _item('c10', 'Classic Ultra', categoryCigarettes, 25.0),
        _item('c11', 'Classic Regular', categoryCigarettes, 25.0),
        _item('c12', 'Marlboro Red', categoryCigarettes, 25.0),
      ];

  static InventoryItem _item(String id, String name, String category, double sellingPrice) {
    final now = DateTime.now();
    return InventoryItem(
      id: '', // Will be assigned by Firestore doc()
      name: name,
      category: category,
      sellingPrice: sellingPrice,
      purchasePrice: (sellingPrice * 0.7).roundToDouble(), // Placeholder purchase price
      currentStock: 50, // Temporary dummy stock value for development
      totalPurchased: 50,
      totalSold: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}
