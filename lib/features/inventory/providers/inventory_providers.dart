import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/inventory/data/inventory_repository.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/domain/config/initial_inventory.dart';

import 'package:snooker_club/core/providers/club_scope_provider.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return InventoryRepository(ref.watch(firestoreServiceProvider).db, clubId: clubId);
});

final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  if (repo.clubId == null) return Stream.value([]);
  return repo.watchInventory();
});

// A provider for selected date in stock history
final stockHistoryDateProvider = NotifierProvider<StockHistoryDateNotifier, DateTime>(StockHistoryDateNotifier.new);

class StockHistoryDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  
  void setDate(DateTime date) => state = date;
}

final stockHistoryProvider = StreamProvider<List<StockHistory>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  if (repo.clubId == null) return Stream.value([]);
  final date = ref.watch(stockHistoryDateProvider);
  return repo.watchStockHistory(date);
});

final inventoryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final itemsAsync = ref.watch(inventoryItemsProvider);
  
  return itemsAsync.when(
    data: (items) {
      int totalProducts = items.length;
      int lowStockCount = items.where((i) => i.isLowStock).length;
      int outOfStockCount = items.where((i) => i.isOutOfStock).length;
      int totalStockItems = items.fold(0, (sum, i) => sum + i.currentStock);
      double inventoryValue = items.fold(0.0, (sum, i) => sum + (i.currentStock * i.purchasePrice));

      return {
        'totalProducts': totalProducts,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'totalStockItems': totalStockItems,
        'inventoryValue': inventoryValue,
      };
    },
    loading: () => {
      'totalProducts': 0,
      'lowStockCount': 0,
      'outOfStockCount': 0,
      'totalStockItems': 0,
      'inventoryValue': 0.0,
    },
    error: (_, __) => {
      'totalProducts': 0,
      'lowStockCount': 0,
      'outOfStockCount': 0,
      'totalStockItems': 0,
      'inventoryValue': 0.0,
    },
  );
});

// Seed data function
final inventorySeederProvider = Provider((ref) {
  return () async {
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.seedInitialInventory(InitialInventory.items);
  };
});

