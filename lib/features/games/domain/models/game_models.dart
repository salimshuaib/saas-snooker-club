import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum TableType {
  snooker,
  indianPool,
  americanPool,
  ps5,
  ps4,
  pc,
  carrom,
  foosball,
  chess,
  tableTennis,
  steeringWheel,
  arcade,
  simulator,
  iceHockey;

  String get displayName {
    switch (this) {
      case TableType.snooker:
        return 'Snooker';
      case TableType.indianPool:
        return 'Indian Pool';
      case TableType.americanPool:
        return 'American Pool';
      case TableType.ps5:
        return 'PS5';
      case TableType.ps4:
        return 'PS4';
      case TableType.pc:
        return 'PC';
      case TableType.carrom:
        return 'Carrom';
      case TableType.foosball:
        return 'Foosball';
      case TableType.chess:
        return 'Chess';
      case TableType.tableTennis:
        return 'Table Tennis';
      case TableType.steeringWheel:
        return 'Steering Wheel';
      case TableType.arcade:
        return 'Arcade';
      case TableType.simulator:
        return 'Simulator';
      case TableType.iceHockey:
        return 'Ice Hockey';
    }
  }

  bool get isOtherGame {
    return this != TableType.snooker &&
        this != TableType.indianPool &&
        this != TableType.americanPool;
  }
}

enum GameType {
  standard,
  race,
  rummy;

  String get displayName {
    switch (this) {
      case GameType.standard:
        return 'Standard';
      case GameType.race:
        return 'Race';
      case GameType.rummy:
        return 'Rummy';
    }
  }
}

enum TableStatus {
  available,
  running,
  paused,
  billing,
  cancelled,
  pendingBill;

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.running:
        return 'Running';
      case TableStatus.paused:
        return 'Paused';
      case TableStatus.billing:
        return 'Billing';
      case TableStatus.cancelled:
        return 'Cancelled';
      case TableStatus.pendingBill:
        return 'Pending Bill';
    }
  }
}

enum GameMode { team, solo }

enum BillingType {
  perMinute,
  perFrame,
  halfHour,
  oneHour,
  customMinute,
  perCoin;

  String get displayName {
    switch (this) {
      case BillingType.perMinute:
        return 'Per Minute';
      case BillingType.perFrame:
        return 'Per Frame';
      case BillingType.halfHour:
        return 'Half Hour (30 min)';
      case BillingType.oneHour:
        return 'One Hour (60 min)';
      case BillingType.customMinute:
        return 'Custom Minute';
      case BillingType.perCoin:
        return 'Per Coin';
    }
  }
}

enum MatchType {
  friendly,
  loserPays;

  String get displayName {
    switch (this) {
      case MatchType.friendly:
        return 'Friendly';
      case MatchType.loserPays:
        return 'Loser Pays (T.P.)';
    }
  }
}

enum PaymentMethod {
  cash,
  upi,
  credit;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }
}

// ─────────────────────────────────────────────
// TableModel
// ─────────────────────────────────────────────

class TableBillingOption {
  final bool enabled;
  final double price;
  final double? extraCharge;

  const TableBillingOption({
    required this.enabled,
    required this.price,
    this.extraCharge,
  });

  TableBillingOption copyWith({
    bool? enabled,
    double? price,
    double? extraCharge,
  }) {
    return TableBillingOption(
      enabled: enabled ?? this.enabled,
      price: price ?? this.price,
      extraCharge: extraCharge ?? this.extraCharge,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'price': price,
      if (extraCharge != null) 'extraCharge': extraCharge,
    };
  }

  factory TableBillingOption.fromMap(Map<String, dynamic> map) {
    return TableBillingOption(
      enabled: map['enabled'] as bool? ?? true,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      extraCharge: (map['extraCharge'] as num?)?.toDouble(),
    );
  }
}

class TableModel {
  final String id;
  final String name;
  final TableType type;
  final TableStatus status;
  final String? activeGameId;
  final int order;
  final Map<String, TableBillingOption>? billingOptions;
  final bool isMinimumBillEnabled;
  final double minimumBillAmount;
  final bool allowCustomPrice;
  final bool isTimeNotSure;
  final String? floorId;
  final String? floorName;

  const TableModel({
    required this.id,
    required this.name,
    required this.type,
    this.status = TableStatus.available,
    this.activeGameId,
    this.order = 0,
    this.billingOptions,
    this.isMinimumBillEnabled = false,
    this.minimumBillAmount = 0.0,
    this.allowCustomPrice = false,
    this.isTimeNotSure = false,
    this.floorId,
    this.floorName,
  });

  TableModel copyWith({
    String? id,
    String? name,
    TableType? type,
    TableStatus? status,
    String? activeGameId,
    int? order,
    Map<String, TableBillingOption>? billingOptions,
    bool? isMinimumBillEnabled,
    double? minimumBillAmount,
    bool? allowCustomPrice,
    bool? isTimeNotSure,
    String? floorId,
    String? floorName,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      activeGameId: activeGameId ?? this.activeGameId,
      order: order ?? this.order,
      billingOptions: billingOptions ?? this.billingOptions,
      isMinimumBillEnabled: isMinimumBillEnabled ?? this.isMinimumBillEnabled,
      minimumBillAmount: minimumBillAmount ?? this.minimumBillAmount,
      allowCustomPrice: allowCustomPrice ?? this.allowCustomPrice,
      isTimeNotSure: isTimeNotSure ?? this.isTimeNotSure,
      floorId: floorId ?? this.floorId,
      floorName: floorName ?? this.floorName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'activeGameId': activeGameId,
      'order': order,
      if (billingOptions != null)
        'billingOptions': billingOptions!.map((k, v) => MapEntry(k, v.toMap())),
      'isMinimumBillEnabled': isMinimumBillEnabled,
      'minimumBillAmount': minimumBillAmount,
      'allowCustomPrice': allowCustomPrice,
      'isTimeNotSure': isTimeNotSure,
      'floorId': floorId,
      'floorName': floorName,
    };
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TableType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TableType.snooker,
      ),
      status: TableStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      activeGameId: map['activeGameId'] as String?,
      order: map['order'] as int? ?? 0,
      billingOptions: map['billingOptions'] != null
          ? (map['billingOptions'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                k,
                TableBillingOption.fromMap(v as Map<String, dynamic>),
              ),
            )
          : null,
      isMinimumBillEnabled: map['isMinimumBillEnabled'] as bool? ?? false,
      minimumBillAmount: (map['minimumBillAmount'] as num?)?.toDouble() ?? 0.0,
      allowCustomPrice: map['allowCustomPrice'] as bool? ?? false,
      isTimeNotSure: map['isTimeNotSure'] as bool? ?? false,
      floorId: map['floorId'] as String?,
      floorName: map['floorName'] as String?,
    );
  }
}

// ─────────────────────────────────────────────
// GameOrder
// ─────────────────────────────────────────────

class GameOrder {
  final String id;
  final String productId;
  final String productName;
  final String category;
  final String? playerName;
  final int quantity;
  final double pricePerUnit;

  const GameOrder({
    required this.id,
    required this.productId,
    required this.productName,
    required this.category,
    this.playerName,
    required this.quantity,
    required this.pricePerUnit,
  });

  double get total => quantity * pricePerUnit;

  GameOrder copyWith({
    String? id,
    String? productId,
    String? productName,
    String? category,
    String? playerName,
    int? quantity,
    double? pricePerUnit,
  }) {
    return GameOrder(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      playerName: playerName ?? this.playerName,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'category': category,
      'playerName': playerName,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
    };
  }

  factory GameOrder.fromMap(Map<String, dynamic> map) {
    return GameOrder(
      id: map['id'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      category: map['category'] as String,
      playerName: map['playerName'] as String?,
      quantity: (map['quantity'] as num).toInt(),
      pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────
// ManualGameCharge
// ─────────────────────────────────────────────

class ManualGameChargeGroup {
  final ManualGameCharge charge;
  final int quantity;
  final double totalAmount;
  final List<ManualGameCharge> originalCharges;

  double get totalDiscountAmount =>
      originalCharges.fold(0.0, (sum, charge) => sum + charge.appliedDiscountAmount);

  double get finalAmount =>
      originalCharges.fold(0.0, (sum, charge) => sum + charge.finalAmount);

  const ManualGameChargeGroup({
    required this.charge,
    required this.quantity,
    required this.totalAmount,
    required this.originalCharges,
  });
}

extension ManualGameChargeListExtension on List<ManualGameCharge> {
  List<ManualGameChargeGroup> grouped() {
    final Map<String, List<ManualGameCharge>> map = {};
    for (final g in this) {
      final key = '${g.tableId}_${g.gameType.name}_${g.billingType.name}_${g.durationSeconds}_${g.frames}_${g.coins}_${g.calculatedAmount}_${g.discountAmount}';
      map.putIfAbsent(key, () => []).add(g);
    }
    return map.values.map((list) => ManualGameChargeGroup(
      charge: list.first,
      quantity: list.length,
      totalAmount: list.fold<double>(0, (s, e) => s + e.calculatedAmount),
      originalCharges: list,
    )).toList();
  }
}

class ManualGameCharge {
  final String id;
  final String tableId;
  final String tableName;
  final TableType tableType;
  final GameType gameType;
  final BillingType billingType;
  final int? durationSeconds;
  final int? frames;
  final int? playersCount;
  final int? coins;
  final double calculatedAmount;
  final double discountAmount;

  const ManualGameCharge({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.tableType,
    required this.gameType,
    required this.billingType,
    this.durationSeconds,
    this.frames,
    this.playersCount,
    this.coins,
    required this.calculatedAmount,
    this.discountAmount = 0.0,
  });

  double get appliedDiscountAmount =>
      discountAmount.clamp(0.0, calculatedAmount).toDouble();

  double get finalAmount => calculatedAmount - appliedDiscountAmount;

  ManualGameCharge copyWith({
    double? calculatedAmount,
    double? discountAmount,
  }) {
    return ManualGameCharge(
      id: id,
      tableId: tableId,
      tableName: tableName,
      tableType: tableType,
      gameType: gameType,
      billingType: billingType,
      durationSeconds: durationSeconds,
      frames: frames,
      playersCount: playersCount,
      coins: coins,
      calculatedAmount: calculatedAmount ?? this.calculatedAmount,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tableId': tableId,
      'tableName': tableName,
      'tableType': tableType.name,
      'gameType': gameType.name,
      'billingType': billingType.name,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (frames != null) 'frames': frames,
      if (playersCount != null) 'playersCount': playersCount,
      if (coins != null) 'coins': coins,
      'calculatedAmount': calculatedAmount,
      'discountAmount': discountAmount,
    };
  }

  factory ManualGameCharge.fromMap(Map<String, dynamic> map) {
    return ManualGameCharge(
      id: map['id'] ?? '',
      tableId: map['tableId'] ?? '',
      tableName: map['tableName'] ?? '',
      tableType: TableType.values.firstWhere(
        (e) => e.name == map['tableType'],
        orElse: () => TableType.snooker,
      ),
      gameType: GameType.values.firstWhere(
        (e) => e.name == map['gameType'],
        orElse: () => GameType.standard,
      ),
      billingType: BillingType.values.firstWhere(
        (e) => e.name == map['billingType'],
        orElse: () => BillingType.perMinute,
      ),
      durationSeconds: map['durationSeconds']?.toInt(),
      frames: map['frames']?.toInt(),
      playersCount: map['playersCount']?.toInt(),
      coins: map['coins']?.toInt(),
      calculatedAmount: (map['calculatedAmount'] ?? 0).toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─────────────────────────────────────────────
// GameChargeBreakdown
// ─────────────────────────────────────────────

class GameChargeBreakdown {
  final double baseCharge;
  final int overtimeMinutes;
  final double overtimeCharge;
  final double minimumBillAdjustment;

  const GameChargeBreakdown({
    required this.baseCharge,
    required this.overtimeMinutes,
    required this.overtimeCharge,
    this.minimumBillAdjustment = 0.0,
  });

  double get totalCharge => baseCharge + overtimeCharge + minimumBillAdjustment;
}

// ─────────────────────────────────────────────
// GameRound
// ─────────────────────────────────────────────

class GameRound {
  final int roundNumber;
  final String? winner; // Player name or Team A / Team B
  final String? loser; // Player name or Team A / Team B
  final List<String>? framePayers;
  final double roundCost;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final int? gracePeriodMinutes;
  final int? overtimeMinutes;
  final double? overtimeCharge;

  const GameRound({
    required this.roundNumber,
    this.winner,
    this.loser,
    this.framePayers,
    required this.roundCost,
    this.startTime,
    this.endTime,
    this.durationSeconds,
    this.gracePeriodMinutes,
    this.overtimeMinutes,
    this.overtimeCharge,
  });

  GameRound copyWith({
    int? roundNumber,
    String? winner,
    String? loser,
    List<String>? framePayers,
    double? roundCost,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    int? gracePeriodMinutes,
    int? overtimeMinutes,
    double? overtimeCharge,
  }) {
    return GameRound(
      roundNumber: roundNumber ?? this.roundNumber,
      winner: winner ?? this.winner,
      loser: loser ?? this.loser,
      framePayers: framePayers ?? this.framePayers,
      roundCost: roundCost ?? this.roundCost,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      overtimeCharge: overtimeCharge ?? this.overtimeCharge,
    );
  }

  Map<String, dynamic> toMap() => {
    'roundNumber': roundNumber,
    'winner': winner,
    'loser': loser,
    'framePayers': framePayers,
    'roundCost': roundCost,
    'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
    'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    'durationSeconds': durationSeconds,
    'gracePeriodMinutes': gracePeriodMinutes,
    'overtimeMinutes': overtimeMinutes,
    'overtimeCharge': overtimeCharge,
  };

  factory GameRound.fromMap(Map<String, dynamic> map) => GameRound(
    roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 1,
    winner: map['winner'] as String?,
    loser: map['loser'] as String?,
    framePayers: map['framePayers'] != null
        ? List<String>.from(map['framePayers'])
        : null,
    roundCost: (map['roundCost'] as num?)?.toDouble() ?? 0.0,
    startTime: map['startTime'] != null
        ? (map['startTime'] is Timestamp
              ? (map['startTime'] as Timestamp).toDate()
              : DateTime.tryParse(map['startTime'].toString()))
        : null,
    endTime: map['endTime'] != null
        ? (map['endTime'] is Timestamp
              ? (map['endTime'] as Timestamp).toDate()
              : DateTime.tryParse(map['endTime'].toString()))
        : null,
    durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
    gracePeriodMinutes: (map['gracePeriodMinutes'] as num?)?.toInt(),
    overtimeMinutes: (map['overtimeMinutes'] as num?)?.toInt(),
    overtimeCharge: (map['overtimeCharge'] as num?)?.toDouble(),
  );
}

// ─────────────────────────────────────────────
// GameSession
// ─────────────────────────────────────────────

class WaitlistPlayer {
  final String? id;
  final String name;
  final DateTime addedAt;
  final bool isPaid;

  WaitlistPlayer({
    this.id, 
    required this.name, 
    DateTime? addedAt, 
    this.isPaid = false,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id, 
    'name': name,
    'addedAt': addedAt.millisecondsSinceEpoch,
    'isPaid': isPaid,
  };

  factory WaitlistPlayer.fromMap(Map<String, dynamic> map) => WaitlistPlayer(
    id: map['id'] as String?,
    name: map['name'] as String? ?? '',
    addedAt: map['addedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int)
        : DateTime.now(),
    isPaid: map['isPaid'] as bool? ?? false,
  );

  WaitlistPlayer copyWith({
    String? id,
    String? name,
    DateTime? addedAt,
    bool? isPaid,
  }) {
    return WaitlistPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      addedAt: addedAt ?? this.addedAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class GameSession {
  final String? createdByUserId;
  final String? createdByName;
  final String? updatedByUserId;
  final String? updatedByName;
  final String? endedByUserId;
  final String? endedByName;
  final String? processedByUserId;
  final String? processedByName;
  final String? cancelledByUserId;
  final String? cancelledByName;
  final String id;
  final String tableId;
  final String tableName;
  final TableType tableType;
  final String? floorId;
  final String? floorName;
  final GameType gameType;
  final int? targetPoints;
  final Map<String, int>? playerPoints;
  final GameMode mode;
  final BillingType billingType;
  final MatchType matchType;
  final List<String> teamA;
  final List<String> teamB;
  List<String> get players => allPlayers;
  final List<String> playerIds;
  final Map<String, String>? playerIdentities;
  final TableStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final List<DateTime> pauseTimes;
  final List<DateTime> resumeTimes;
  final int totalFrames;
  final int framesPlayed;
  final int? customMinutes;
  final List<GameOrder> orders;
  final List<ManualGameCharge> manualGameCharges;
  final List<GameRound> rounds;
  final Map<String, Map<PaymentMethod, double>>? playerPaymentSplits;
  final Map<String, double>? playerLiabilities;
  final String? winnerId; // player name or "Team A" / "Team B"
  final List<String>? selectedPayers;
  final double? discountAmount;
  final double? discountedGameCharge;
  final double? currentGameDiscountAmount;
  final String? paidBy; // customer name paying (for credit)
  final PaymentMethod? paymentMethod;
  final String? paymentStatus;

  final String? pendingBillCustomerId;
  final String? pendingBillCustomerName;
  final DateTime? markedPendingAt;
  final String? markedPendingByUserId;
  final String? markedPendingByName;
 // e.g., 'Outstanding', 'Partially Paid', 'Paid'
  final double? paidAmount;
  final double? remainingAmount;
  final double? gameCharge;
  final double? baseGameCharge;
  final int? overtimeMinutes;
  final double? overtimeCharge;
  final double? ordersTotal;
  final double? grandTotal;
  final double? roundedAmount;
  final double? finalAmount;
  final String? employeeId;
  final String date; // YYYY-MM-DD for Firestore date queries
  final List<AuditLog> auditLogs;
  final bool isManualEntry;
  final bool isCancelled;
  final DateTime? recordedTime;
  final PricingSettings? pricingSnapshot;
  final GameSettings? gameSettingsSnapshot;
  final double? customExtraCharge;
  final bool isMinimumBillEnabled;
  final double minimumBillAmount;
  final int? coinQuantity;
  final double? customPrice;
  final bool isTimeNotSure;
  final double? manualSelectedFinalAmount;
  final DateTime? alarmTime;
  final String? alarmSetByUserId;
  final List<WaitlistPlayer> waitlistPlayers;

  const GameSession({
    this.createdByUserId,
    this.createdByName,
    this.updatedByUserId,
    this.updatedByName,
    this.endedByUserId,
    this.endedByName,
    this.processedByUserId,
    this.processedByName,
    this.cancelledByUserId,
    this.cancelledByName,
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.tableType,
    this.floorId,
    this.floorName,
    this.gameType = GameType.standard,
    this.targetPoints,
    this.playerPoints,
    required this.mode,
    required this.billingType,
    required this.matchType,
    required this.teamA,
    this.teamB = const [],
    this.playerIds = const [],
    this.playerIdentities,
    required this.status,
    required this.startTime,
    this.endTime,
    this.pauseTimes = const [],
    this.resumeTimes = const [],
    this.totalFrames = 1,
    this.framesPlayed = 0,
    this.customMinutes,
    this.orders = const [],
    this.manualGameCharges = const [],
    this.rounds = const [],
    this.playerPaymentSplits,
    this.playerLiabilities,
    this.winnerId,
    this.selectedPayers,
    this.discountAmount,
    this.discountedGameCharge,
    this.currentGameDiscountAmount,
    this.paidBy,
    this.paymentMethod,
    this.paymentStatus,
    this.pendingBillCustomerId,
    this.pendingBillCustomerName,
    this.markedPendingAt,
    this.markedPendingByUserId,
    this.markedPendingByName,
    this.paidAmount,
    this.remainingAmount,
    this.gameCharge,
    this.baseGameCharge,
    this.overtimeMinutes,
    this.overtimeCharge,
    this.ordersTotal,
    this.grandTotal,
    this.roundedAmount,
    this.finalAmount,
    this.employeeId,
    required this.date,
    this.auditLogs = const [],
    this.isManualEntry = false,
    this.isCancelled = false,
    this.recordedTime,
    this.pricingSnapshot,
    this.gameSettingsSnapshot,
    this.customExtraCharge,
    this.isMinimumBillEnabled = false,
    this.minimumBillAmount = 0.0,
    this.coinQuantity,
    this.customPrice,
    this.isTimeNotSure = false,
    this.manualSelectedFinalAmount,
    this.alarmTime,
    this.alarmSetByUserId,
    this.waitlistPlayers = const [],
  });

  /// All players involved (team A + team B)
  List<String> get allPlayers => [...teamA, ...teamB];

  /// Returns the display name for the winner (e.g. expands "Team A" to player names)
  String? get winnerDisplayName {
    if (winnerId == 'Team A') {
      return teamA.join(' & ');
    } else if (winnerId == 'Team B') {
      return teamB.join(' & ');
    }
    return winnerId;
  }

  /// Returns the display name for the loser (e.g. expands "Team B" to player names)
  String? get loserDisplayName {
    if (winnerId == null) return null;
    if (mode == GameMode.team) {
      if (winnerId == 'Team A') {
        return teamB.join(' & ');
      } else {
        return teamA.join(' & ');
      }
    } else {
      final losers = allPlayers.where((p) => p != winnerId).toList();
      return losers.join(', ');
    }
  }

  /// Calculate how many seconds the game has been actively running.
  /// Paused durations are excluded.
  int get activeSeconds {
    final now = endTime ?? DateTime.now();
    int totalPausedMs = 0;
    final pairs = pauseTimes.length;
    for (int i = 0; i < pairs; i++) {
      final pause = pauseTimes[i];
      final resume = (i < resumeTimes.length)
          ? resumeTimes[i]
          : (endTime ?? DateTime.now());
      totalPausedMs += resume.difference(pause).inMilliseconds;
    }

    final elapsedMs = now.difference(startTime).inMilliseconds - totalPausedMs;
    return (elapsedMs / 1000).round().clamp(0, 999999);
  }

  bool get isActive =>
      status == TableStatus.running || status == TableStatus.paused;

  GameSession copyWith({
    String? createdByUserId,
    String? createdByName,
    String? updatedByUserId,
    String? updatedByName,
    String? endedByUserId,
    String? endedByName,
    String? processedByUserId,
    String? processedByName,
    String? cancelledByUserId,
    String? cancelledByName,
    String? id,
    String? tableId,
    String? tableName,
    TableType? tableType,
    String? floorId,
    String? floorName,
    GameType? gameType,
    int? targetPoints,
    Map<String, int>? playerPoints,
    GameMode? mode,
    BillingType? billingType,
    MatchType? matchType,
    List<String>? teamA,
    List<String>? teamB,
    List<String>? playerIds,
    Map<String, String>? playerIdentities,
    TableStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    List<DateTime>? pauseTimes,
    List<DateTime>? resumeTimes,
    int? totalFrames,
    int? framesPlayed,
    int? customMinutes,
    List<GameOrder>? orders,
    List<ManualGameCharge>? manualGameCharges,
    List<GameRound>? rounds,
    Map<String, Map<PaymentMethod, double>>? playerPaymentSplits,
    Map<String, double>? playerLiabilities,
    String? winnerId,
    List<String>? selectedPayers,
    double? discountAmount,
    double? discountedGameCharge,
    double? currentGameDiscountAmount,
    String? paidBy,
    PaymentMethod? paymentMethod,
    String? paymentStatus,
    String? pendingBillCustomerId,
    String? pendingBillCustomerName,
    DateTime? markedPendingAt,
    String? markedPendingByUserId,
    String? markedPendingByName,
    double? paidAmount,
    double? remainingAmount,
    double? gameCharge,
    double? baseGameCharge,
    int? overtimeMinutes,
    double? overtimeCharge,
    double? ordersTotal,
    double? grandTotal,
    double? roundedAmount,
    double? finalAmount,
    String? employeeId,
    String? date,
    List<AuditLog>? auditLogs,
    bool? isManualEntry,
    bool? isCancelled,
    DateTime? recordedTime,
    PricingSettings? pricingSnapshot,
    GameSettings? gameSettingsSnapshot,
    double? customExtraCharge,
    bool? isMinimumBillEnabled,
    double? minimumBillAmount,
    int? coinQuantity,
    double? customPrice,
    bool? isTimeNotSure,
    double? manualSelectedFinalAmount,
    DateTime? alarmTime,
    String? alarmSetByUserId,
    List<WaitlistPlayer>? waitlistPlayers,
  }) {
    return GameSession(
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      updatedByName: updatedByName ?? this.updatedByName,
      endedByUserId: endedByUserId ?? this.endedByUserId,
      endedByName: endedByName ?? this.endedByName,
      processedByUserId: processedByUserId ?? this.processedByUserId,
      processedByName: processedByName ?? this.processedByName,
      cancelledByUserId: cancelledByUserId ?? this.cancelledByUserId,
      cancelledByName: cancelledByName ?? this.cancelledByName,
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      tableType: tableType ?? this.tableType,
      floorId: floorId ?? this.floorId,
      floorName: floorName ?? this.floorName,
      gameType: gameType ?? this.gameType,
      targetPoints: targetPoints ?? this.targetPoints,
      playerPoints: playerPoints ?? this.playerPoints,
      mode: mode ?? this.mode,
      billingType: billingType ?? this.billingType,
      matchType: matchType ?? this.matchType,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      playerIds: playerIds ?? this.playerIds,
      playerIdentities: playerIdentities ?? this.playerIdentities,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pauseTimes: pauseTimes ?? this.pauseTimes,
      resumeTimes: resumeTimes ?? this.resumeTimes,
      totalFrames: totalFrames ?? this.totalFrames,
      framesPlayed: framesPlayed ?? this.framesPlayed,
      customMinutes: customMinutes ?? this.customMinutes,
      orders: orders ?? this.orders,
      manualGameCharges: manualGameCharges ?? this.manualGameCharges,
      rounds: rounds ?? this.rounds,
      playerPaymentSplits: playerPaymentSplits ?? this.playerPaymentSplits,
      playerLiabilities: playerLiabilities ?? this.playerLiabilities,
      winnerId: winnerId ?? this.winnerId,
      selectedPayers: selectedPayers ?? this.selectedPayers,
      discountAmount: discountAmount ?? this.discountAmount,
      discountedGameCharge: discountedGameCharge ?? this.discountedGameCharge,
      currentGameDiscountAmount:
          currentGameDiscountAmount ?? this.currentGameDiscountAmount,
      paidBy: paidBy ?? this.paidBy,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,

      pendingBillCustomerId: pendingBillCustomerId ?? this.pendingBillCustomerId,
      pendingBillCustomerName: pendingBillCustomerName ?? this.pendingBillCustomerName,
      markedPendingAt: markedPendingAt ?? this.markedPendingAt,
      markedPendingByUserId: markedPendingByUserId ?? this.markedPendingByUserId,
      markedPendingByName: markedPendingByName ?? this.markedPendingByName,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      gameCharge: gameCharge ?? this.gameCharge,
      baseGameCharge: baseGameCharge ?? this.baseGameCharge,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      overtimeCharge: overtimeCharge ?? this.overtimeCharge,
      ordersTotal: ordersTotal ?? this.ordersTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      roundedAmount: roundedAmount ?? this.roundedAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      auditLogs: auditLogs ?? this.auditLogs,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      isCancelled: isCancelled ?? this.isCancelled,
      recordedTime: recordedTime ?? this.recordedTime,
      pricingSnapshot: pricingSnapshot ?? this.pricingSnapshot,
      gameSettingsSnapshot: gameSettingsSnapshot ?? this.gameSettingsSnapshot,
      customExtraCharge: customExtraCharge ?? this.customExtraCharge,
      isMinimumBillEnabled: isMinimumBillEnabled ?? this.isMinimumBillEnabled,
      minimumBillAmount: minimumBillAmount ?? this.minimumBillAmount,
      coinQuantity: coinQuantity ?? this.coinQuantity,
      customPrice: customPrice ?? this.customPrice,
      isTimeNotSure: isTimeNotSure ?? this.isTimeNotSure,
      manualSelectedFinalAmount: manualSelectedFinalAmount ?? this.manualSelectedFinalAmount,
      alarmTime: alarmTime ?? this.alarmTime,
      alarmSetByUserId: alarmSetByUserId ?? this.alarmSetByUserId,
      waitlistPlayers: waitlistPlayers ?? this.waitlistPlayers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'updatedByUserId': updatedByUserId,
      'updatedByName': updatedByName,
      'endedByUserId': endedByUserId,
      'endedByName': endedByName,
      'processedByUserId': processedByUserId,
      'processedByName': processedByName,
      'cancelledByUserId': cancelledByUserId,
      'cancelledByName': cancelledByName,
      'id': id,
      'tableId': tableId,
      'tableName': tableName,
      'tableType': tableType.name,
      'floorId': floorId,
      'floorName': floorName,
      'gameCategory': tableType.isOtherGame ? 'other_game' : 'table_game',
      'gameType': gameType.name,
      'targetPoints': targetPoints,
      'playerPoints': playerPoints,
      'mode': mode.name,
      'billingType': billingType.name,
      'matchType': matchType.name,
      'teamA': teamA,
      'teamB': teamB,
      'playerIds': playerIds,
      'playerIdentities': playerIdentities,
      'status': status.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'pauseTimes': pauseTimes.map((d) => Timestamp.fromDate(d)).toList(),
      'resumeTimes': resumeTimes.map((d) => Timestamp.fromDate(d)).toList(),
      'totalFrames': totalFrames,
      'framesPlayed': framesPlayed,
      if (customMinutes != null) 'customMinutes': customMinutes,
      'orders': orders.map((o) => o.toMap()).toList(),
      'manualGameCharges': manualGameCharges.map((g) => g.toMap()).toList(),
      'rounds': rounds.map((r) => r.toMap()).toList(),
      'playerPaymentSplits': playerPaymentSplits?.map(
        (k, v) => MapEntry(k, v.map((k2, v2) => MapEntry(k2.name, v2))),
      ),
      'playerLiabilities': playerLiabilities,
      'winnerId': winnerId,
      'selectedPayers': selectedPayers,
      'discountAmount': discountAmount,
      'discountedGameCharge': discountedGameCharge,
      'currentGameDiscountAmount': currentGameDiscountAmount,
      'roundedAmount': roundedAmount,
      'finalAmount': finalAmount,
      'paidBy': paidBy,
      'paymentMethod': paymentMethod?.name,
      'paymentStatus': paymentStatus,

      'pendingBillCustomerId': pendingBillCustomerId,
      'pendingBillCustomerName': pendingBillCustomerName,
      'markedPendingAt': markedPendingAt?.toIso8601String(),
      'markedPendingByUserId': markedPendingByUserId,
      'markedPendingByName': markedPendingByName,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'gameCharge': gameCharge,
      'baseGameCharge': baseGameCharge,
      'overtimeMinutes': overtimeMinutes,
      'overtimeCharge': overtimeCharge,
      'ordersTotal': ordersTotal,
      'grandTotal': grandTotal,
      'employeeId': employeeId,
      'date': date,
      'auditLogs': auditLogs.map((a) => a.toMap()).toList(),
      'isManualEntry': isManualEntry,
      'isCancelled': isCancelled,
      'recordedTime': recordedTime != null
          ? Timestamp.fromDate(recordedTime!)
          : null,
      'pricingSnapshot': pricingSnapshot?.toMap(),
      'gameSettingsSnapshot': gameSettingsSnapshot?.toMap(),
      'customExtraCharge': customExtraCharge,
      'isMinimumBillEnabled': isMinimumBillEnabled,
      'minimumBillAmount': minimumBillAmount,
      'coinQuantity': coinQuantity,
      'customPrice': customPrice,
      'isTimeNotSure': isTimeNotSure,
      'manualSelectedFinalAmount': manualSelectedFinalAmount,
      'alarmTime': alarmTime != null ? Timestamp.fromDate(alarmTime!) : null,
      'alarmSetByUserId': alarmSetByUserId,
      'waitlistPlayers': waitlistPlayers.map((p) => p.toMap()).toList(),
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    List<DateTime> parseDateList(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) => (e as Timestamp).toDate()).toList();
    }

    return GameSession(
      createdByUserId: map['createdByUserId'] as String?,
      createdByName: map['createdByName'] as String?,
      updatedByUserId: map['updatedByUserId'] as String?,
      updatedByName: map['updatedByName'] as String?,
      endedByUserId: map['endedByUserId'] as String?,
      endedByName: map['endedByName'] as String?,
      processedByUserId: map['processedByUserId'] as String?,
      processedByName: map['processedByName'] as String?,
      cancelledByUserId: map['cancelledByUserId'] as String?,
      cancelledByName: map['cancelledByName'] as String?,
      id: map['id'] as String,
      tableId: map['tableId'] as String,
      tableName: map['tableName'] as String? ?? '',
      gameType: GameType.values.firstWhere(
        (t) => t.name == map['gameType'],
        orElse: () => GameType.standard,
      ),
      targetPoints: map['targetPoints'],
      playerPoints: map['playerPoints'] != null
          ? Map<String, int>.from(map['playerPoints'])
          : null,
      tableType: TableType.values.firstWhere(
        (t) => t.name == map['tableType'],
        orElse: () => TableType.snooker,
      ),
      floorId: map['floorId'] as String?,
      floorName: map['floorName'] as String?,
      mode: GameMode.values.firstWhere(
        (m) => m.name == map['mode'],
        orElse: () => GameMode.solo,
      ),
      billingType: BillingType.values.firstWhere(
        (b) => b.name == map['billingType'],
        orElse: () => BillingType.perMinute,
      ),
      matchType: MatchType.values.firstWhere(
        (m) => m.name == map['matchType'],
        orElse: () => MatchType.friendly,
      ),
      teamA: List<String>.from(map['teamA'] ?? []),
      teamB: List<String>.from(map['teamB'] ?? []),
      playerIds: List<String>.from(map['playerIds'] ?? []),
      playerIdentities: map['playerIdentities'] != null
          ? Map<String, String>.from(map['playerIdentities'])
          : null,
      status: TableStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      startTime: map['startTime'] is String ? DateTime.parse(map['startTime']) : (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] is String ? DateTime.parse(map['endTime']) : (map['endTime'] as Timestamp).toDate())
          : null,
      pauseTimes: parseDateList(map['pauseTimes']),
      resumeTimes: parseDateList(map['resumeTimes']),
      totalFrames: (map['totalFrames'] as num?)?.toInt() ?? 1,
      framesPlayed: (map['framesPlayed'] as num?)?.toInt() ?? 0,
      customMinutes: (map['customMinutes'] as num?)?.toInt(),
      orders:
          (map['orders'] as List<dynamic>?)
              ?.map((o) => GameOrder.fromMap(o as Map<String, dynamic>))
              .toList() ??
          [],
      manualGameCharges:
          (map['manualGameCharges'] as List<dynamic>?)
              ?.map((g) => ManualGameCharge.fromMap(g as Map<String, dynamic>))
              .toList() ??
          [],
      rounds:
          (map['rounds'] as List<dynamic>?)
              ?.map((r) => GameRound.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      playerPaymentSplits: () {
        if (map['playerPaymentSplits'] != null) {
          final splits = map['playerPaymentSplits'] as Map<String, dynamic>;
          return splits.map((player, methodsMap) {
            final parsedMethods = (methodsMap as Map<String, dynamic>).map((
              methodName,
              amount,
            ) {
              final method = PaymentMethod.values.firstWhere(
                (p) => p.name == methodName,
                orElse: () => PaymentMethod.cash,
              );
              return MapEntry(method, (amount as num).toDouble());
            });
            return MapEntry(player, parsedMethods);
          });
        }
        if (map['playerPaymentMethods'] != null) {
          final legacy = map['playerPaymentMethods'] as Map<String, dynamic>;
          final liabilities = map['playerLiabilities'] as Map<String, dynamic>?;
          return legacy.map((player, methodName) {
            final method = PaymentMethod.values.firstWhere(
              (p) => p.name == methodName,
              orElse: () => PaymentMethod.cash,
            );
            final amount = (liabilities?[player] as num?)?.toDouble() ?? 0.0;
            return MapEntry(player, {method: amount});
          });
        }
        return null;
      }(),
      playerLiabilities: map['playerLiabilities'] != null
          ? (map['playerLiabilities'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            )
          : null,
      winnerId: map['winnerId'] as String?,
      selectedPayers: map['selectedPayers'] != null
          ? List<String>.from(map['selectedPayers'])
          : null,
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      discountedGameCharge: (map['discountedGameCharge'] as num?)?.toDouble(),
      currentGameDiscountAmount:
          (map['currentGameDiscountAmount'] as num?)?.toDouble(),
      customExtraCharge: (map['customExtraCharge'] as num?)?.toDouble(),
      isMinimumBillEnabled: map['isMinimumBillEnabled'] as bool? ?? false,
      minimumBillAmount: (map['minimumBillAmount'] as num?)?.toDouble() ?? 0.0,
      coinQuantity: (map['coinQuantity'] as num?)?.toInt(),
      paidBy: map['paidBy'] as String?,
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (p) => p.name == map['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      paymentStatus: map['paymentStatus'] as String?,

      pendingBillCustomerId: map['pendingBillCustomerId'] as String?,
      pendingBillCustomerName: map['pendingBillCustomerName'] as String?,
      markedPendingAt: map['markedPendingAt'] != null ? DateTime.parse(map['markedPendingAt'] as String) : null,
      markedPendingByUserId: map['markedPendingByUserId'] as String?,
      markedPendingByName: map['markedPendingByName'] as String?,
      alarmTime: (map['alarmTime'] as Timestamp?)?.toDate(),
      alarmSetByUserId: map['alarmSetByUserId'] as String?,
      paidAmount: (map['paidAmount'] as num?)?.toDouble(),
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble(),
      gameCharge: (map['gameCharge'] as num?)?.toDouble(),
      baseGameCharge: (map['baseGameCharge'] as num?)?.toDouble(),
      overtimeMinutes: (map['overtimeMinutes'] as num?)?.toInt(),
      overtimeCharge: (map['overtimeCharge'] as num?)?.toDouble(),
      ordersTotal: (map['ordersTotal'] as num?)?.toDouble(),
      grandTotal: (map['grandTotal'] as num?)?.toDouble(),
      roundedAmount: (map['roundedAmount'] as num?)?.toDouble(),
      finalAmount: (map['finalAmount'] as num?)?.toDouble(),
      employeeId: map['employeeId'] as String?,
      date: map['date'] as String,
      auditLogs:
          (map['auditLogs'] as List<dynamic>?)
              ?.map((a) => AuditLog.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      isManualEntry: map['isManualEntry'] as bool? ?? false,
      isCancelled: map['isCancelled'] as bool? ?? false,
      recordedTime: map['recordedTime'] != null
          ? (map['recordedTime'] is Timestamp
                ? (map['recordedTime'] as Timestamp).toDate()
                : DateTime.tryParse(map['recordedTime'].toString()))
          : null,
      pricingSnapshot: map['pricingSnapshot'] != null
          ? PricingSettings.fromMap(map['pricingSnapshot'])
          : null,
      gameSettingsSnapshot: map['gameSettingsSnapshot'] != null
          ? GameSettings.fromMap(map['gameSettingsSnapshot'])
          : null,
      customPrice: (map['customPrice'] as num?)?.toDouble(),
      isTimeNotSure: map['isTimeNotSure'] ?? false,
      manualSelectedFinalAmount: (map['manualSelectedFinalAmount'] as num?)?.toDouble(),
      waitlistPlayers:
          (map['waitlistPlayers'] as List<dynamic>?)
              ?.map((p) => WaitlistPlayer.fromMap(Map<String, dynamic>.from(p)))
              .toList() ??
          const [],
    );
  }
}

// Stub for OtherGameResource
class OtherGameResource {
  final String id;
  final String name;
  final TableStatus status;
  final bool isActive;
  final String category;
  final Map<String, double> pricing;

  OtherGameResource({
    required this.id,
    required this.name,
    required this.status,
    required this.isActive,
    required this.category,
    required this.pricing,
  });

  factory OtherGameResource.fromMap(Map<String, dynamic> map) {
    return OtherGameResource(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      status: TableStatus.available,
      isActive: map['isActive'] ?? true,
      category: map['category'] ?? '',
      pricing: {},
    );
  }
}
class AddItemsResult { final List<GameOrder> orders; final List<ManualGameCharge> manualGameCharges; AddItemsResult(this.orders, this.manualGameCharges); }

