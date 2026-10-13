import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final double purchasePrice;
  final int currentStock;
  final int totalPurchased;
  final int totalSold;
  final bool isActive;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    this.purchasePrice = 0.0,
    this.currentStock = 0,
    this.totalPurchased = 0,
    this.totalSold = 0,
    this.isActive = true,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Dynamic settings hooks updated by Settings Module
  static int lowStockThreshold = 5;
  static int defaultInitialQuantity = 10;
  static bool enableLowStockAlerts = true;

  bool get isFood => category.trim().toLowerCase() == 'food';
  bool get isLowStock =>
      !isFood &&
      enableLowStockAlerts &&
      currentStock > 0 &&
      currentStock <= lowStockThreshold;
  bool get isOutOfStock => isFood ? !isAvailable : currentStock <= 0;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? sellingPrice,
    double? purchasePrice,
    int? currentStock,
    int? totalPurchased,
    int? totalSold,
    bool? isActive,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentStock: currentStock ?? this.currentStock,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      totalSold: totalSold ?? this.totalSold,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'sellingPrice': sellingPrice,
      'purchasePrice': purchasePrice,
      'currentStock': currentStock,
      'totalPurchased': totalPurchased,
      'totalSold': totalSold,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory InventoryItem.fromMap(String id, Map<String, dynamic> map) {
    return InventoryItem(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      currentStock: map['currentStock'] as int? ?? 0,
      totalPurchased: map['totalPurchased'] as int? ?? 0,
      totalSold: map['totalSold'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      isAvailable: map['isAvailable'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class StockHistory {
  final String id;
  final String productId;
  final String productName;
  final int quantityAdded;
  final double purchasePrice;
  final String employeeName;
  final String? notes;
  final DateTime date;

  const StockHistory({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityAdded,
    required this.purchasePrice,
    required this.employeeName,
    this.notes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityAdded': quantityAdded,
      'purchasePrice': purchasePrice,
      'employeeName': employeeName,
      'notes': notes,
      'date': Timestamp.fromDate(date),
    };
  }

  factory StockHistory.fromMap(String id, Map<String, dynamic> map) {
    return StockHistory(
      id: id,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantityAdded: map['quantityAdded'] as int? ?? 0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      employeeName: map['employeeName'] as String? ?? 'Admin',
      notes: map['notes'] as String?,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
