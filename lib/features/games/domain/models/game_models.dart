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
  pc,
  carrom,
  foosball,
  chess,
  tableTennis,
  steeringWheel,
  arcade;

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
  billing;

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
    }
  }
}

enum GameMode {
  team,
  solo;

  String get displayName {
    switch (this) {
      case GameMode.team:
        return 'Team';
      case GameMode.solo:
        return 'Solo';
    }
  }
}

enum BillingType {
  perMinute,
  perFrame,
  halfHour,
  oneHour,
  perCoin;

  String get displayName {
    switch (this) {
      case BillingType.perMinute:
        return 'Per Minute';
      case BillingType.perFrame:
        return 'Per Frame';
      case BillingType.halfHour:
        return 'Half Hour';
      case BillingType.oneHour:
        return '1 Hour';
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
  final Map<String, double>? controllerPrices;

  const TableBillingOption({
    required this.enabled,
    required this.price,
    this.controllerPrices,
  });

  TableBillingOption copyWith({
    bool? enabled,
    double? price,
    Map<String, double>? controllerPrices,
  }) {
    return TableBillingOption(
      enabled: enabled ?? this.enabled,
      price: price ?? this.price,
      controllerPrices: controllerPrices ?? this.controllerPrices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'price': price,
      if (controllerPrices != null) 'controllerPrices': controllerPrices,
    };
  }

  factory TableBillingOption.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const TableBillingOption(enabled: false, price: 0.0);
    }
    return TableBillingOption(
      enabled: map['enabled'] as bool? ?? false,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      controllerPrices: map['controllerPrices'] != null
          ? Map<String, double>.from(
              (map['controllerPrices'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : null,
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

  const TableModel({
    required this.id,
    required this.name,
    required this.type,
    this.status = TableStatus.available,
    this.activeGameId,
    this.order = 0,
    this.billingOptions,
  });

  TableModel copyWith({
    String? id,
    String? name,
    TableType? type,
    TableStatus? status,
    String? activeGameId,
    int? order,
    Map<String, TableBillingOption>? billingOptions,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      activeGameId: activeGameId ?? this.activeGameId,
      order: order ?? this.order,
      billingOptions: billingOptions ?? this.billingOptions,
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
    };
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    Map<String, TableBillingOption>? parsedOptions;
    if (map['billingOptions'] != null) {
      final Map<String, dynamic> rawOptions = Map<String, dynamic>.from(map['billingOptions'] as Map);
      parsedOptions = rawOptions.map(
        (key, value) => MapEntry(key, TableBillingOption.fromMap(value as Map<String, dynamic>?)),
      );
    }

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
      billingOptions: parsedOptions,
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
// GameChargeBreakdown
// ─────────────────────────────────────────────

class GameChargeBreakdown {
  final double baseCharge;
  final int overtimeMinutes;
  final double overtimeCharge;

  const GameChargeBreakdown({
    required this.baseCharge,
    required this.overtimeMinutes,
    required this.overtimeCharge,
  });

  double get totalCharge => baseCharge + overtimeCharge;
}

// ─────────────────────────────────────────────
// GameRound
// ─────────────────────────────────────────────

class GameRound {
  final int roundNumber;
  final String? winner; // Player name or Team A / Team B
  final String? loser; // Player name or Team A / Team B
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

class GameSession {
  final String? createdByUserId;
  final String? createdByName;
  final String? updatedByUserId;
  final String? updatedByName;
  final String id;
  final String tableId;
  final String tableName;
  final TableType tableType;
  final GameType gameType;
  final int? targetPoints;
  final Map<String, int>? playerPoints;
  final GameMode mode;
  final BillingType billingType;
  final MatchType matchType;
  final List<String> teamA;
  final List<String> teamB;
  final List<String> playerIds;
  final Map<String, String>? playerIdentities;
  final TableStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final List<DateTime> pauseTimes;
  final List<DateTime> resumeTimes;
  final int totalFrames;
  final int framesPlayed;
  final List<GameOrder> orders;
  final List<GameRound> rounds;
  final Map<String, PaymentMethod>? playerPaymentMethods;
  final Map<String, double>? playerLiabilities;
  final String? winnerId; // player name or "Team A" / "Team B"
  final String? paidBy; // customer name paying (for credit)
  final PaymentMethod? paymentMethod;
  final String? paymentStatus; // e.g., 'Outstanding', 'Partially Paid', 'Paid'
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
  final double? discountedGameCharge;
  final double? gameDiscountAmount;
  final double? gameDiscountPercentage;
  final String? employeeId;
  final String date; // YYYY-MM-DD for Firestore date queries
  final List<AuditLog> auditLogs;
  final bool isManualEntry;
  final DateTime? recordedTime;
  final PricingSettings? pricingSnapshot;
  final GameSettings? gameSettingsSnapshot;
  final double? customPrice;
  final int? controllerCount;
  final int? coinQuantity;

  const GameSession({
    this.createdByUserId,
    this.createdByName,
    this.updatedByUserId,
    this.updatedByName,
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.tableType,
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
    this.orders = const [],
    this.rounds = const [],
    this.playerPaymentMethods,
    this.playerLiabilities,
    this.winnerId,
    this.paidBy,
    this.paymentMethod,
    this.paymentStatus,
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
    this.discountedGameCharge,
    this.gameDiscountAmount,
    this.gameDiscountPercentage,
    this.employeeId,
    required this.date,
    this.auditLogs = const [],
    this.isManualEntry = false,
    this.recordedTime,
    this.pricingSnapshot,
    this.gameSettingsSnapshot,
    this.customPrice,
    this.controllerCount,
    this.coinQuantity,
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
      final resume =
          (i < resumeTimes.length) ? resumeTimes[i] : (endTime ?? DateTime.now());
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
    String? id,
    String? tableId,
    String? tableName,
    TableType? tableType,
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
    List<GameOrder>? orders,
    List<GameRound>? rounds,
    Map<String, PaymentMethod>? playerPaymentMethods,
    Map<String, double>? playerLiabilities,
    String? winnerId,
    String? paidBy,
    PaymentMethod? paymentMethod,
    String? paymentStatus,
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
    double? discountedGameCharge,
    double? gameDiscountAmount,
    double? gameDiscountPercentage,
    String? employeeId,
    String? date,
    List<AuditLog>? auditLogs,
    bool? isManualEntry,
    DateTime? recordedTime,
    PricingSettings? pricingSnapshot,
    GameSettings? gameSettingsSnapshot,
    double? customPrice,
    int? controllerCount,
    int? coinQuantity,
  }) {
    return GameSession(
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      updatedByName: updatedByName ?? this.updatedByName,
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      tableType: tableType ?? this.tableType,
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
      orders: orders ?? this.orders,
      rounds: rounds ?? this.rounds,
      playerPaymentMethods: playerPaymentMethods ?? this.playerPaymentMethods,
      playerLiabilities: playerLiabilities ?? this.playerLiabilities,
      winnerId: winnerId ?? this.winnerId,
      paidBy: paidBy ?? this.paidBy,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
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
      discountedGameCharge: discountedGameCharge ?? this.discountedGameCharge,
      gameDiscountAmount: gameDiscountAmount ?? this.gameDiscountAmount,
      gameDiscountPercentage: gameDiscountPercentage ?? this.gameDiscountPercentage,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      auditLogs: auditLogs ?? this.auditLogs,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      recordedTime: recordedTime ?? this.recordedTime,
      pricingSnapshot: pricingSnapshot ?? this.pricingSnapshot,
      gameSettingsSnapshot: gameSettingsSnapshot ?? this.gameSettingsSnapshot,
      customPrice: customPrice ?? this.customPrice,
      controllerCount: controllerCount ?? this.controllerCount,
      coinQuantity: coinQuantity ?? this.coinQuantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'updatedByUserId': updatedByUserId,
      'updatedByName': updatedByName,
      'id': id,
      'tableId': tableId,
      'tableName': tableName,
      'tableType': tableType.name,
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
      'orders': orders.map((o) => o.toMap()).toList(),
      'rounds': rounds.map((r) => r.toMap()).toList(),
      'playerPaymentMethods': playerPaymentMethods?.map((k, v) => MapEntry(k, v.name)),
      'playerLiabilities': playerLiabilities,
      'winnerId': winnerId,
      'paidBy': paidBy,
      'paymentMethod': paymentMethod?.name,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'gameCharge': gameCharge,
      'baseGameCharge': baseGameCharge,
      'overtimeMinutes': overtimeMinutes,
      'overtimeCharge': overtimeCharge,
      'ordersTotal': ordersTotal,
      'grandTotal': grandTotal,
      'roundedAmount': roundedAmount,
      'finalAmount': finalAmount,
      'discountedGameCharge': discountedGameCharge,
      'gameDiscountAmount': gameDiscountAmount,
      'gameDiscountPercentage': gameDiscountPercentage,
      'employeeId': employeeId,
      'date': date,
      'auditLogs': auditLogs.map((a) => a.toMap()).toList(),
      'isManualEntry': isManualEntry,
      'recordedTime': recordedTime != null ? Timestamp.fromDate(recordedTime!) : null,
      'pricingSnapshot': pricingSnapshot?.toMap(),
      'gameSettingsSnapshot': gameSettingsSnapshot?.toMap(),
      'customPrice': customPrice,
      'controllerCount': controllerCount,
      'coinQuantity': coinQuantity,
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    List<DateTime> parseDateList(dynamic raw) {
      if (raw == null) return [];
      return (raw as List)
          .map((e) => (e as Timestamp).toDate())
          .toList();
    }

    return GameSession(
            createdByUserId: map['createdByUserId'] as String?,
      createdByName: map['createdByName'] as String?,
      updatedByUserId: map['updatedByUserId'] as String?,
      updatedByName: map['updatedByName'] as String?,
      id: map['id'] as String,
      tableId: map['tableId'] as String,
      tableName: map['tableName'] as String? ?? '',
      gameType: GameType.values.firstWhere(
        (t) => t.name == map['gameType'],
        orElse: () => GameType.standard,
      ),
      targetPoints: map['targetPoints'],
      playerPoints: map['playerPoints'] != null ? Map<String, int>.from(map['playerPoints']) : null,
      tableType: TableType.values.firstWhere(
        (t) => t.name == map['tableType'],
        orElse: () => TableType.snooker,
      ),
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
        playerIdentities: map['playerIdentities'] != null ? Map<String, String>.from(map['playerIdentities']) : null,
      status: TableStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      pauseTimes: parseDateList(map['pauseTimes']),
      resumeTimes: parseDateList(map['resumeTimes']),
      totalFrames: (map['totalFrames'] as num?)?.toInt() ?? 1,
      framesPlayed: (map['framesPlayed'] as num?)?.toInt() ?? 0,
      orders: (map['orders'] as List<dynamic>?)
              ?.map((o) => GameOrder.fromMap(o as Map<String, dynamic>))
              .toList() ??
          [],
      rounds: (map['rounds'] as List<dynamic>?)
              ?.map((r) => GameRound.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      playerPaymentMethods: map['playerPaymentMethods'] != null
          ? (map['playerPaymentMethods'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                PaymentMethod.values.firstWhere(
                  (p) => p.name == value,
                  orElse: () => PaymentMethod.cash,
                ),
              ),
            )
          : null,
      playerLiabilities: map['playerLiabilities'] != null
          ? (map['playerLiabilities'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            )
          : null,
      winnerId: map['winnerId'] as String?,
      paidBy: map['paidBy'] as String?,
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (p) => p.name == map['paymentMethod'],
              orElse: () => PaymentMethod.cash,
      ) : null,
      paymentStatus: map['paymentStatus'] as String?,
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
      discountedGameCharge: (map['discountedGameCharge'] as num?)?.toDouble(),
      gameDiscountAmount: (map['gameDiscountAmount'] as num?)?.toDouble(),
      gameDiscountPercentage: (map['gameDiscountPercentage'] as num?)?.toDouble(),
      employeeId: map['employeeId'] as String?,
      date: map['date'] as String,
      auditLogs: (map['auditLogs'] as List<dynamic>?)
              ?.map((a) => AuditLog.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      isManualEntry: map['isManualEntry'] as bool? ?? false,
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
      controllerCount: (map['controllerCount'] as num?)?.toInt(),
      coinQuantity: (map['coinQuantity'] as num?)?.toInt(),
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
