import 'package:snooker_club/features/games/domain/models/game_models.dart';

class BusinessSettings {
  final String clubName;
  final String address;
  final String contactNumber;
  final String? gstNumber;
  final String? logoUrl;

  const BusinessSettings({
    this.clubName = 'Snooker Club',
    this.address = 'Main Club Complex, City Center',
    this.contactNumber = '+91 9876543210',
    this.gstNumber,
    this.logoUrl,
  });

  BusinessSettings copyWith({
    String? clubName,
    String? address,
    String? contactNumber,
    String? gstNumber,
    String? logoUrl,
  }) {
    return BusinessSettings(
      clubName: clubName ?? this.clubName,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubName': clubName,
      'address': address,
      'contactNumber': contactNumber,
      'gstNumber': gstNumber,
      'logoUrl': logoUrl,
    };
  }

  factory BusinessSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const BusinessSettings();
    return BusinessSettings(
      clubName: map['clubName'] as String? ?? 'Snooker Club',
      address: map['address'] as String? ?? 'Main Club Complex, City Center',
      contactNumber: map['contactNumber'] as String? ?? '+91 9876543210',
      gstNumber: map['gstNumber'] as String?,
      logoUrl: map['logoUrl'] as String?,
    );
  }
}

class GameSettings {
  final int frameGracePeriodMinutes;
  final bool enableOvertimeBilling;
  final bool allowPauseResume;
  final int maxPlayersPerTeam;
  final MatchType defaultMatchType;

  const GameSettings({
    this.frameGracePeriodMinutes = 20,
    this.enableOvertimeBilling = true,
    this.allowPauseResume = true,
    this.maxPlayersPerTeam = 3,
    this.defaultMatchType = MatchType.friendly,
  });

  GameSettings copyWith({
    int? frameGracePeriodMinutes,
    bool? enableOvertimeBilling,
    bool? allowPauseResume,
    int? maxPlayersPerTeam,
    MatchType? defaultMatchType,
  }) {
    return GameSettings(
      frameGracePeriodMinutes: frameGracePeriodMinutes ?? this.frameGracePeriodMinutes,
      enableOvertimeBilling: enableOvertimeBilling ?? this.enableOvertimeBilling,
      allowPauseResume: allowPauseResume ?? this.allowPauseResume,
      maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
      defaultMatchType: defaultMatchType ?? this.defaultMatchType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frameGracePeriodMinutes': frameGracePeriodMinutes,
      'enableOvertimeBilling': enableOvertimeBilling,
      'allowPauseResume': allowPauseResume,
      'maxPlayersPerTeam': maxPlayersPerTeam,
      'defaultMatchType': defaultMatchType.name,
    };
  }

  factory GameSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GameSettings();
    return GameSettings(
      frameGracePeriodMinutes: (map['frameGracePeriodMinutes'] as num?)?.toInt() ?? 20,
      enableOvertimeBilling: map['enableOvertimeBilling'] as bool? ?? true,
      allowPauseResume: map['allowPauseResume'] as bool? ?? true,
      maxPlayersPerTeam: (map['maxPlayersPerTeam'] as num?)?.toInt() ?? 3,
      defaultMatchType: MatchType.values.firstWhere(
        (m) => m.name == map['defaultMatchType'],
        orElse: () => MatchType.friendly,
      ),
    );
  }
}

class PricingSettings {
  // Snooker
  final double snookerPerMinute;
  final double snookerHalfHour;
  final double snookerOneHour;

  // Indian Pool
  final double indianPoolPerFrame;
  final double indianPoolPerMinute;
  final double indianPoolHalfHour;
  final double indianPoolOneHour;

  // American Pool
  final double americanPoolPerFrame;
  final double americanPoolPerMinute;
  final double americanPoolHalfHour;
  final double americanPoolOneHour;
  
  final double snookerRacePerMinute;
  final double indianPoolRacePerMinute;
  final double americanPoolRacePerMinute;
  final double snookerRummyPerMinute;

  final double ps5HalfHour;
  final double ps5OneHour;
  final double pcHalfHour;
  final double pcOneHour;
  final double carromHalfHour;
  final double carromOneHour;
  final double foosballHalfHour;
  final double foosballOneHour;
  final double chessHalfHour;
  final double chessOneHour;

  const PricingSettings({
    this.snookerPerMinute = 4.50,
    this.snookerHalfHour = 135.00,
    this.snookerOneHour = 270.00,
    this.indianPoolPerFrame = 40.00,
    this.indianPoolPerMinute = 3.50,
    this.indianPoolHalfHour = 100.00,
    this.indianPoolOneHour = 210.00,
    this.americanPoolPerFrame = 60.00,
    this.americanPoolPerMinute = 4.00,
    this.americanPoolHalfHour = 150.00,
    this.americanPoolOneHour = 240.00,
    this.snookerRacePerMinute = 3.00,
    this.indianPoolRacePerMinute = 3.00,
    this.americanPoolRacePerMinute = 4.00,
    this.snookerRummyPerMinute = 4.00,
    this.ps5HalfHour = 100.00,
    this.ps5OneHour = 200.00,
    this.pcHalfHour = 80.00,
    this.pcOneHour = 150.00,
    this.carromHalfHour = 50.00,
    this.carromOneHour = 90.00,
    this.foosballHalfHour = 60.00,
    this.foosballOneHour = 100.00,
    this.chessHalfHour = 30.00,
    this.chessOneHour = 50.00,
  });

  PricingSettings copyWith({
    double? snookerPerMinute,
    double? snookerHalfHour,
    double? snookerOneHour,
    double? indianPoolPerFrame,
    double? indianPoolPerMinute,
    double? indianPoolHalfHour,
    double? indianPoolOneHour,
    double? americanPoolPerFrame,
    double? americanPoolPerMinute,
    double? americanPoolHalfHour,
    double? americanPoolOneHour,
    double? snookerRacePerMinute,
    double? indianPoolRacePerMinute,
    double? americanPoolRacePerMinute,
    double? snookerRummyPerMinute,
    double? ps5HalfHour,
    double? ps5OneHour,
    double? pcHalfHour,
    double? pcOneHour,
    double? carromHalfHour,
    double? carromOneHour,
    double? foosballHalfHour,
    double? foosballOneHour,
    double? chessHalfHour,
    double? chessOneHour,
  }) {
    return PricingSettings(
      snookerPerMinute: snookerPerMinute ?? this.snookerPerMinute,
      snookerHalfHour: snookerHalfHour ?? this.snookerHalfHour,
      snookerOneHour: snookerOneHour ?? this.snookerOneHour,
      indianPoolPerFrame: indianPoolPerFrame ?? this.indianPoolPerFrame,
      indianPoolPerMinute: indianPoolPerMinute ?? this.indianPoolPerMinute,
      indianPoolHalfHour: indianPoolHalfHour ?? this.indianPoolHalfHour,
      indianPoolOneHour: indianPoolOneHour ?? this.indianPoolOneHour,
      americanPoolPerFrame: americanPoolPerFrame ?? this.americanPoolPerFrame,
      americanPoolPerMinute: americanPoolPerMinute ?? this.americanPoolPerMinute,
      americanPoolHalfHour: americanPoolHalfHour ?? this.americanPoolHalfHour,
      americanPoolOneHour: americanPoolOneHour ?? this.americanPoolOneHour,
      snookerRacePerMinute: snookerRacePerMinute ?? this.snookerRacePerMinute,
      indianPoolRacePerMinute: indianPoolRacePerMinute ?? this.indianPoolRacePerMinute,
      americanPoolRacePerMinute: americanPoolRacePerMinute ?? this.americanPoolRacePerMinute,
      snookerRummyPerMinute: snookerRummyPerMinute ?? this.snookerRummyPerMinute,
      ps5HalfHour: ps5HalfHour ?? this.ps5HalfHour,
      ps5OneHour: ps5OneHour ?? this.ps5OneHour,
      pcHalfHour: pcHalfHour ?? this.pcHalfHour,
      pcOneHour: pcOneHour ?? this.pcOneHour,
      carromHalfHour: carromHalfHour ?? this.carromHalfHour,
      carromOneHour: carromOneHour ?? this.carromOneHour,
      foosballHalfHour: foosballHalfHour ?? this.foosballHalfHour,
      foosballOneHour: foosballOneHour ?? this.foosballOneHour,
      chessHalfHour: chessHalfHour ?? this.chessHalfHour,
      chessOneHour: chessOneHour ?? this.chessOneHour,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'snookerPerMinute': snookerPerMinute,
      'snookerHalfHour': snookerHalfHour,
      'snookerOneHour': snookerOneHour,
      'indianPoolPerFrame': indianPoolPerFrame,
      'indianPoolPerMinute': indianPoolPerMinute,
      'indianPoolHalfHour': indianPoolHalfHour,
      'indianPoolOneHour': indianPoolOneHour,
      'americanPoolPerFrame': americanPoolPerFrame,
      'americanPoolPerMinute': americanPoolPerMinute,
      'americanPoolHalfHour': americanPoolHalfHour,
      'americanPoolOneHour': americanPoolOneHour,
      'snookerRacePerMinute': snookerRacePerMinute,
      'indianPoolRacePerMinute': indianPoolRacePerMinute,
      'americanPoolRacePerMinute': americanPoolRacePerMinute,
      'snookerRummyPerMinute': snookerRummyPerMinute,
      'ps5HalfHour': ps5HalfHour,
      'ps5OneHour': ps5OneHour,
      'pcHalfHour': pcHalfHour,
      'pcOneHour': pcOneHour,
      'carromHalfHour': carromHalfHour,
      'carromOneHour': carromOneHour,
      'foosballHalfHour': foosballHalfHour,
      'foosballOneHour': foosballOneHour,
      'chessHalfHour': chessHalfHour,
      'chessOneHour': chessOneHour,
    };
  }

  factory PricingSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PricingSettings();
    return PricingSettings(
      snookerPerMinute: (map['snookerPerMinute'] as num?)?.toDouble() ?? 4.50,
      snookerHalfHour: (map['snookerHalfHour'] as num?)?.toDouble() ?? 135.00,
      snookerOneHour: (map['snookerOneHour'] as num?)?.toDouble() ?? 270.00,
      indianPoolPerFrame: (map['indianPoolPerFrame'] as num?)?.toDouble() ?? 40.00,
      indianPoolPerMinute: (map['indianPoolPerMinute'] as num?)?.toDouble() ?? 3.50,
      indianPoolHalfHour: (map['indianPoolHalfHour'] as num?)?.toDouble() ?? 100.00,
      indianPoolOneHour: (map['indianPoolOneHour'] as num?)?.toDouble() ?? 210.00,
      americanPoolPerFrame: (map['americanPoolPerFrame'] as num?)?.toDouble() ?? 60.00,
      americanPoolPerMinute: (map['americanPoolPerMinute'] as num?)?.toDouble() ?? 4.00,
      americanPoolHalfHour: (map['americanPoolHalfHour'] as num?)?.toDouble() ?? 150.00,
      americanPoolOneHour: (map['americanPoolOneHour'] as num?)?.toDouble() ?? 240.00,
      snookerRacePerMinute: (map['snookerRacePerMinute'] as num?)?.toDouble() ?? 3.00,
      indianPoolRacePerMinute: (map['indianPoolRacePerMinute'] as num?)?.toDouble() ?? 3.00,
      americanPoolRacePerMinute: (map['americanPoolRacePerMinute'] as num?)?.toDouble() ?? 4.00,
      snookerRummyPerMinute: (map['snookerRummyPerMinute'] as num?)?.toDouble() ?? 4.00,
      ps5HalfHour: (map['ps5HalfHour'] as num?)?.toDouble() ?? 100.00,
      ps5OneHour: (map['ps5OneHour'] as num?)?.toDouble() ?? 200.00,
      pcHalfHour: (map['pcHalfHour'] as num?)?.toDouble() ?? 80.00,
      pcOneHour: (map['pcOneHour'] as num?)?.toDouble() ?? 150.00,
      carromHalfHour: (map['carromHalfHour'] as num?)?.toDouble() ?? 50.00,
      carromOneHour: (map['carromOneHour'] as num?)?.toDouble() ?? 90.00,
      foosballHalfHour: (map['foosballHalfHour'] as num?)?.toDouble() ?? 60.00,
      foosballOneHour: (map['foosballOneHour'] as num?)?.toDouble() ?? 100.00,
      chessHalfHour: (map['chessHalfHour'] as num?)?.toDouble() ?? 30.00,
      chessOneHour: (map['chessOneHour'] as num?)?.toDouble() ?? 50.00,
    );
  }
}

class InventorySettings {
  final int lowStockThreshold;
  final int defaultInitialQuantity;
  final bool enableLowStockAlerts;

  const InventorySettings({
    this.lowStockThreshold = 5,
    this.defaultInitialQuantity = 10,
    this.enableLowStockAlerts = true,
  });

  InventorySettings copyWith({
    int? lowStockThreshold,
    int? defaultInitialQuantity,
    bool? enableLowStockAlerts,
  }) {
    return InventorySettings(
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      defaultInitialQuantity: defaultInitialQuantity ?? this.defaultInitialQuantity,
      enableLowStockAlerts: enableLowStockAlerts ?? this.enableLowStockAlerts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lowStockThreshold': lowStockThreshold,
      'defaultInitialQuantity': defaultInitialQuantity,
      'enableLowStockAlerts': enableLowStockAlerts,
    };
  }

  factory InventorySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const InventorySettings();
    return InventorySettings(
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 5,
      defaultInitialQuantity: (map['defaultInitialQuantity'] as num?)?.toInt() ?? 10,
      enableLowStockAlerts: map['enableLowStockAlerts'] as bool? ?? true,
    );
  }
}

class SecuritySettings {
  final String adminPasscode;
  final bool requirePasscodeForDeletion;

  const SecuritySettings({
    this.adminPasscode = '96430',
    this.requirePasscodeForDeletion = true,
  });

  SecuritySettings copyWith({
    String? adminPasscode,
    bool? requirePasscodeForDeletion,
  }) {
    return SecuritySettings(
      adminPasscode: adminPasscode ?? this.adminPasscode,
      requirePasscodeForDeletion: requirePasscodeForDeletion ?? this.requirePasscodeForDeletion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminPasscode': adminPasscode,
      'requirePasscodeForDeletion': requirePasscodeForDeletion,
    };
  }

  factory SecuritySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SecuritySettings();
    return SecuritySettings(
      adminPasscode: map['adminPasscode'] as String? ?? '96430',
      requirePasscodeForDeletion: map['requirePasscodeForDeletion'] as bool? ?? true,
    );
  }
}

class NotificationSettings {
  final bool lowStockAlerts;
  final bool dailyRevenueSummary;
  final bool backupReminders;

  const NotificationSettings({
    this.lowStockAlerts = true,
    this.dailyRevenueSummary = true,
    this.backupReminders = false,
  });

  NotificationSettings copyWith({
    bool? lowStockAlerts,
    bool? dailyRevenueSummary,
    bool? backupReminders,
  }) {
    return NotificationSettings(
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      dailyRevenueSummary: dailyRevenueSummary ?? this.dailyRevenueSummary,
      backupReminders: backupReminders ?? this.backupReminders,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lowStockAlerts': lowStockAlerts,
      'dailyRevenueSummary': dailyRevenueSummary,
      'backupReminders': backupReminders,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationSettings();
    return NotificationSettings(
      lowStockAlerts: map['lowStockAlerts'] as bool? ?? true,
      dailyRevenueSummary: map['dailyRevenueSummary'] as bool? ?? true,
      backupReminders: map['backupReminders'] as bool? ?? false,
    );
  }
}

class AppSettings {
  final BusinessSettings business;
  final GameSettings game;
  final PricingSettings pricing;
  final InventorySettings inventory;
  final SecuritySettings security;
  final NotificationSettings notifications;
  final DateTime? lastSyncTime;

  const AppSettings({
    this.business = const BusinessSettings(),
    this.game = const GameSettings(),
    this.pricing = const PricingSettings(),
    this.inventory = const InventorySettings(),
    this.security = const SecuritySettings(),
    this.notifications = const NotificationSettings(),
    this.lastSyncTime,
  });

  AppSettings copyWith({
    BusinessSettings? business,
    GameSettings? game,
    PricingSettings? pricing,
    InventorySettings? inventory,
    SecuritySettings? security,
    NotificationSettings? notifications,
    DateTime? lastSyncTime,
  }) {
    return AppSettings(
      business: business ?? this.business,
      game: game ?? this.game,
      pricing: pricing ?? this.pricing,
      inventory: inventory ?? this.inventory,
      security: security ?? this.security,
      notifications: notifications ?? this.notifications,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business': business.toMap(),
      'game': game.toMap(),
      'pricing': pricing.toMap(),
      'inventory': inventory.toMap(),
      'security': security.toMap(),
      'notifications': notifications.toMap(),
      'lastSyncTime': lastSyncTime?.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AppSettings();
    return AppSettings(
      business: BusinessSettings.fromMap(map['business'] as Map<String, dynamic>?),
      game: GameSettings.fromMap(map['game'] as Map<String, dynamic>?),
      pricing: PricingSettings.fromMap(map['pricing'] as Map<String, dynamic>?),
      inventory: InventorySettings.fromMap(map['inventory'] as Map<String, dynamic>?),
      security: SecuritySettings.fromMap(map['security'] as Map<String, dynamic>?),
      notifications: NotificationSettings.fromMap(map['notifications'] as Map<String, dynamic>?),
      lastSyncTime: map['lastSyncTime'] != null ? DateTime.tryParse(map['lastSyncTime'] as String) : null,
    );
  }
}
