import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/core/utils/billing_utils.dart';

/// Centralized pricing and game configuration.

/// Dynamically synchronized with the Settings Module.

class TablePricingConfig {
  TablePricingConfig._();

  // ─── Snooker ───

  static double snookerPerMinute = 4.50;

  static double snookerHalfHour = 135.00;

  static double snookerOneHour = 270.00;

  // ─── Indian Pool ───

  static double indianPoolPerFrame = 40.00;

  static double indianPoolHalfHour = 100.00;

  static double indianPoolOneHour = 210.00;

  static double indianPoolPerMinute = 3.50; // Default for overtime

  // ─── American Pool ───

  static double americanPoolPerFrame = 60.00;

  static double americanPoolPerMinute = 4.00;

  static double americanPoolHalfHour = 150.00;

  static double americanPoolOneHour = 240.00;

  // ─── Settings & Game Rules ───

  static int frameGracePeriodMinutes = 20;

  static bool enableOvertimeBilling = true;

  static bool allowPauseResume = true;

  static int maxPlayersPerTeam = 3;

  static MatchType defaultMatchType = MatchType.friendly;

  /// Checks if a PS5 or Arcade table qualifies for Basement 4 rates:
  /// PS5 12-15, Arcade 12-15, or tables situated on Basement 4.
  static bool isBasement4Ps5(TableModel table) {
    if (table.type != TableType.ps5 && table.type != TableType.arcade) return false;
    final name = table.name.toUpperCase();
    final regex = RegExp(r'(PS5|ARCADE)\s*[-_ ]?\s*(12|13|14|15)\b');
    if (regex.hasMatch(name)) return true;
    final floor = (table.floorName ?? '').toLowerCase();
    if (floor.contains('basement 4') ||
        floor.contains('b4') ||
        floor.contains('basement-4')) {
      return true;
    }
    return false;
  }

  /// Calculates the rate for PS5 according to the Controller-Tiered Matrix:
  /// - 30 Minutes: 1: ₹100 (B4: ₹80), 2: ₹150, 3: ₹220, 4: ₹280 (+₹60/extra)
  /// - 1 Hour: 1: ₹200 (B4: ₹150), 2: ₹240, 3: ₹360, 4: ₹480 (+₹120/extra)
  /// - 1.5 Hours: 1: ₹300 (B4: ₹225), 2: ₹390, 3: ₹570, 4: ₹760 (+₹190/extra)
  static double getPs5TieredRate({
    required TableModel table,
    required BillingType billingType,
    required int controllers,
  }) {
    final bool isB4 = isBasement4Ps5(table);
    final count = controllers < 1 ? 1 : controllers;

    // Check if table has custom controller prices configured
    final customPrices =
        table.billingOptions?[billingType.name]?.controllerPrices;
    if (customPrices != null && customPrices.isNotEmpty) {
      if (customPrices.containsKey(count)) {
        return customPrices[count]!;
      } else if (count > 4 && customPrices.containsKey(4)) {
        final p4 = customPrices[4]!;
        final p3 = customPrices[3] ?? (p4 * 0.75);
        final diff = (p4 - p3) > 0 ? (p4 - p3) : 100.0;
        return p4 + (count - 4) * diff;
      }
    }

    switch (billingType) {
      case BillingType.halfHour:
        if (count == 1) return isB4 ? 80.0 : 100.0;
        if (count == 2) return 150.0;
        if (count == 3) return 220.0;
        if (count == 4) return 280.0;
        return 280.0 + (count - 4) * 60.0;

      case BillingType.oneHour:
        if (count == 1) return isB4 ? 150.0 : 200.0;
        if (count == 2) return 240.0;
        if (count == 3) return 360.0;
        if (count == 4) return 480.0;
        return 480.0 + (count - 4) * 120.0;

      case BillingType.oneHourThirty:
        if (count == 1) return isB4 ? 225.0 : 300.0;
        if (count == 2) return 390.0;
        if (count == 3) return 570.0;
        if (count == 4) return 760.0;
        return 760.0 + (count - 4) * 190.0;

      default:
        return 200.0;
    }
  }

  /// Update active in-memory pricing configuration from AppSettings.

  static void updateFromSettings(AppSettings settings) {
    snookerPerMinute = settings.pricing.snookerPerMinute;

    snookerHalfHour = settings.pricing.snookerHalfHour;

    snookerOneHour = settings.pricing.snookerOneHour;

    indianPoolPerFrame = settings.pricing.indianPoolPerFrame;

    indianPoolPerMinute = settings.pricing.indianPoolPerMinute;

    indianPoolHalfHour = settings.pricing.indianPoolHalfHour;

    indianPoolOneHour = settings.pricing.indianPoolOneHour;

    americanPoolPerFrame = settings.pricing.americanPoolPerFrame;

    americanPoolPerMinute = settings.pricing.americanPoolPerMinute;

    americanPoolHalfHour = settings.pricing.americanPoolHalfHour;

    americanPoolOneHour = settings.pricing.americanPoolOneHour;

    frameGracePeriodMinutes = settings.game.frameGracePeriodMinutes;

    enableOvertimeBilling = settings.game.enableOvertimeBilling;

    allowPauseResume = settings.game.allowPauseResume;

    maxPlayersPerTeam = settings.game.maxPlayersPerTeam;

    // defaultMatchType = settings.game.defaultMatchType;
  }

  /// Returns the per minute price for a table type and game type (used for overtime).

  static double getPerMinutePrice(
    TableModel table,
    GameType gameType,
    PricingSettings pricingConfig,
  ) {
    final tableType = table.type;
    if (table.billingOptions != null) {
      final option = table.billingOptions!['perMinute'];
      if (option != null && option.price > 0) {
        return option.price;
      }
      final otOption = table.billingOptions!['overtime'];
      if (otOption != null && otOption.price > 0) {
        return otOption.price;
      }
    }
    

    switch (tableType) {
      case TableType.snooker:
        return pricingConfig.snookerPerMinute;
      case TableType.indianPool:
        return pricingConfig.indianPoolPerMinute;
      case TableType.americanPool:
        return pricingConfig.americanPoolPerMinute;
      case TableType.ps5:
        return pricingConfig.ps5OneHour / 60.0;
      case TableType.ps4:
        return pricingConfig.ps4OneHour / 60.0;
      case TableType.pc:
        return pricingConfig.pcOneHour / 60.0;
      case TableType.carrom:
        return pricingConfig.carromOneHour / 60.0;
      case TableType.foosball:
        return pricingConfig.foosballOneHour / 60.0;
      case TableType.chess:
        return pricingConfig.chessOneHour / 60.0;
      case TableType.tableTennis:
        return pricingConfig.chessOneHour / 60.0;
      case TableType.steeringWheel:
        return pricingConfig.chessOneHour / 60.0;
      case TableType.simulator:
        return pricingConfig.simulatorOneHour / 60.0;
      case TableType.iceHockey:
        return pricingConfig.iceHockeyOneHour / 60.0;
      case TableType.other:
        return pricingConfig.otherPerMinute;
      case TableType.arcade:
        return 0.0; // Arcade games do not use overtime
    }
  }

  /// Returns the per-minute overtime price for a table.
  /// Checks table.billingOptions['overtime'], then table.billingOptions['perMinute'],
  /// then falls back to default per-minute price.
  static double getOvertimePrice(
    TableModel table,
    GameType gameType,
    PricingSettings pricingConfig,
  ) {
    if (table.billingOptions != null) {
      final otOption = table.billingOptions!['overtime'];
      if (otOption != null && otOption.price > 0) {
        return otOption.price;
      }
      final pmOption = table.billingOptions!['perMinute'];
      if (pmOption != null && pmOption.price > 0) {
        return pmOption.price;
      }
    }
    return getPerMinutePrice(table, gameType, pricingConfig);
  }

  /// Checks if overtime billing is enabled for this table in its config.
  static bool isOvertimeConfiguredEnabled(TableModel table) {
    if (table.billingOptions != null) {
      final otOption = table.billingOptions!['overtime'];
      if (otOption != null) {
        return otOption.enabled;
      }
    }
    return true;
  }

  /// Returns the price for a given table type, game type, and billing type.

  /// Returns null if the combination is not supported.

  static double? getExtraCharge(
    TableModel table,
    GameType gameType,
    BillingType billingType,
    PricingSettings fallbackConfig,
  ) {
    if (table.type != TableType.ps5 &&
        table.type != TableType.ps4 &&
        table.type != TableType.arcade) return 0.0;

    if (table.billingOptions != null && table.billingOptions!.isNotEmpty) {
      final key = billingType.name;
      final option = table.billingOptions![key];
      if (option != null && option.enabled && option.extraCharge != null) {
        return option.extraCharge;
      }
    }

    if (billingType == BillingType.halfHour)
      return fallbackConfig.extraControllerFeeHalfHour;
    if (billingType == BillingType.oneHour)
      return fallbackConfig.extraControllerFeeOneHour;
    if (billingType == BillingType.oneHourThirty)
      return fallbackConfig.extraControllerFeeOneHour * 1.5;
    return 0.0;
  }

  static double? getPrice(
    TableModel table,
    GameType gameType,
    BillingType billingType,
    PricingSettings fallbackConfig,
  ) {
    // If the table has specific billing options configured

    if (table.billingOptions != null && table.billingOptions!.isNotEmpty) {
      String? key;

      if (billingType == BillingType.customMinute) {
        final pmOption = table.billingOptions!['perMinute'];
        if (pmOption != null && pmOption.price > 0) {
          return pmOption.price;
        }
        final otOption = table.billingOptions!['overtime'];
        if (otOption != null && otOption.price > 0) {
          return otOption.price;
        }
      } else {
        key =
            billingType.name; // 'perMinute', 'halfHour', 'oneHour', 'perFrame'
        final option = table.billingOptions![key];
        if (option != null && option.enabled) {
          return option.price;
        }
      }

      return null; // Explicitly configured but disabled or missing
    }

    // Fallback to legacy global logic

    final tableType = table.type;

    

    switch (tableType) {
      case TableType.snooker:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.snookerPerMinute;

          case BillingType.halfHour:
            return fallbackConfig.snookerHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.snookerOneHour;

          default:
            return null;
        }

      case TableType.indianPool:
        switch (billingType) {
          case BillingType.perFrame:
            return fallbackConfig.indianPoolPerFrame;

          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.indianPoolPerMinute;

          case BillingType.halfHour:
            return fallbackConfig.indianPoolHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.indianPoolOneHour;

          default:
            return null;
        }

      case TableType.americanPool:
        switch (billingType) {
          case BillingType.perFrame:
            return fallbackConfig.americanPoolPerFrame;

          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.americanPoolPerMinute;

          case BillingType.halfHour:
            return fallbackConfig.americanPoolHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.americanPoolOneHour;

          default:
            return null;
        }

      case TableType.ps5:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.ps5OneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.ps5HalfHour;

          case BillingType.oneHour:
            return fallbackConfig.ps5OneHour;

          case BillingType.oneHourThirty:
            return fallbackConfig.ps5OneHour * 1.5;

          default:
            return null;
        }

      case TableType.pc:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.pcOneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.pcHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.pcOneHour;

          default:
            return null;
        }

      case TableType.carrom:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.carromOneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.carromHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.carromOneHour;

          default:
            return null;
        }

      case TableType.foosball:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.foosballOneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.foosballHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.foosballOneHour;

          default:
            return null;
        }

      case TableType.chess:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.chessOneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.chessHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.chessOneHour;

          default:
            return null;
        }

      case TableType.tableTennis:
      case TableType.steeringWheel:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.chessOneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.chessHalfHour;
          case BillingType.oneHour:
            return fallbackConfig.chessOneHour;
          default:
            return null;
        }

      case TableType.ps4:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.ps4OneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.ps4HalfHour;
          case BillingType.oneHour:
            return fallbackConfig.ps4OneHour;
          default:
            return null;
        }

      case TableType.simulator:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.simulatorOneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.simulatorHalfHour;
          case BillingType.oneHour:
            return fallbackConfig.simulatorOneHour;
          default:
            return null;
        }

      case TableType.iceHockey:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.iceHockeyOneHour / 60.0;
          case BillingType.halfHour:
            return fallbackConfig.iceHockeyHalfHour;
          case BillingType.oneHour:
            return fallbackConfig.iceHockeyOneHour;
          default:
            return null;
        }

      case TableType.arcade:
        switch (billingType) {
          case BillingType.halfHour:
            return fallbackConfig.ps5HalfHour;
          case BillingType.oneHour:
            return fallbackConfig.ps5OneHour;
          case BillingType.oneHourThirty:
            return fallbackConfig.ps5OneHour * 1.5;
          case BillingType.perCoin:
            return fallbackConfig.arcadeCoinPrice;
          default:
            return null;
        }

      case TableType.other:
        switch (billingType) {
          case BillingType.perMinute:
          case BillingType.customMinute:
            return fallbackConfig.otherPerMinute;
          case BillingType.halfHour:
            return fallbackConfig.otherHalfHour;
          case BillingType.oneHour:
            return fallbackConfig.otherOneHour;
          default:
            return null;
        }
    }
  }

  /// Returns all billing types supported by a given table type and game type.

  static List<BillingType> supportedBillingTypes(
    TableModel table,
    GameType gameType,
  ) {
    final types = _supportedBillingTypesInternal(table, gameType);
    final isConsole = table.type == TableType.ps4 || table.type == TableType.ps5;
    final isArcade = table.type == TableType.arcade;
    
    // Convert to modifiable list if it isn't
    final List<BillingType> result = List.from(types);
    
    if (!isConsole && !isArcade && !result.contains(BillingType.customMinute)) {
      result.add(BillingType.customMinute);
    }
    
    return result;
  }

  static List<BillingType> _supportedBillingTypesInternal(
    TableModel table,
    GameType gameType,
  ) {
    if (table.billingOptions != null && table.billingOptions!.isNotEmpty) {
      final List<BillingType> types = [];

      

      if (table.billingOptions!['perMinute']?.enabled == true)
        types.add(BillingType.perMinute);

      if (table.billingOptions!['perFrame']?.enabled == true)
        types.add(BillingType.perFrame);

      if (table.billingOptions!['halfHour']?.enabled == true)
        types.add(BillingType.halfHour);

      if (table.billingOptions!['oneHour']?.enabled == true)
        types.add(BillingType.oneHour);

      if (table.billingOptions!['oneHourThirty']?.enabled == true)
        types.add(BillingType.oneHourThirty);

      if (table.billingOptions!['perCoin']?.enabled == true)
        types.add(BillingType.perCoin);

      return types;
    }

    // Fallback logic

    final tableType = table.type;

    

    switch (tableType) {
      case TableType.snooker:
        return [
          BillingType.perMinute,
          BillingType.halfHour,
          BillingType.oneHour,
        ];

      case TableType.indianPool:
        return [
          BillingType.perFrame,
          BillingType.perMinute,
          BillingType.halfHour,
          BillingType.oneHour,
        ];

      case TableType.americanPool:
        return [
          BillingType.perFrame,
          BillingType.perMinute,
          BillingType.halfHour,
          BillingType.oneHour,
        ];

      case TableType.ps5:
        return [
          BillingType.halfHour,
          BillingType.oneHour,
          BillingType.oneHourThirty,
        ];

      case TableType.ps4:
      case TableType.pc:
      case TableType.carrom:
      case TableType.foosball:
      case TableType.chess:
      case TableType.tableTennis:
      case TableType.steeringWheel:
      case TableType.simulator:
      case TableType.iceHockey:
        return [BillingType.halfHour, BillingType.oneHour];
      case TableType.arcade:
        return [
          BillingType.halfHour,
          BillingType.oneHour,
          BillingType.oneHourThirty,
          BillingType.perCoin,
        ];

      case TableType.other:
        return [
          BillingType.halfHour,
          BillingType.oneHour,
          BillingType.perMinute,
        ];
    }
  }

  /// Calculate the game charge breakdown for a completed or active session.

  static GameChargeBreakdown calculateCharge({
    required TableModel table,

    required GameType gameType,

    required BillingType billingType,

    required int activeSeconds,

    required int framesPlayed,

    required PricingSettings pricingConfig,

    required GameSettings gameConfig,

    List<GameRound> completedRounds = const [],

    double? customPrice,
    double? customExtraCharge,
    int? coinQuantity,
    int? playersCount,
    int? customMinutes,
    bool isMinimumBillEnabled = false,
    double minimumBillAmount = 0.0,
    bool? isOvertimeEnabled,
  }) {
    final tableType = table.type;
    final bool isTieredCandidate =
        (tableType == TableType.ps5 || tableType == TableType.arcade) &&
            (billingType == BillingType.halfHour ||
                billingType == BillingType.oneHour ||
                billingType == BillingType.oneHourThirty);
    final bool isPs5Tiered =
        isTieredCandidate && gameConfig.isPs5ControllerPricingEnabled();
    final controllers = (playersCount != null && playersCount > 0)
        ? playersCount
        : 1;

    double? basePrice;
    if (isPs5Tiered) {
      basePrice = customPrice ??
          getPs5TieredRate(
            table: table,
            billingType: billingType,
            controllers: controllers,
          );
    } else {
      basePrice = customPrice ??
          getPrice(table, gameType, billingType, pricingConfig);

      if (basePrice != null &&
          (tableType == TableType.ps5 ||
              tableType == TableType.ps4 ||
              tableType == TableType.arcade)) {
        if (controllers > 1) {
          final extraCharge =
              customExtraCharge ??
              getExtraCharge(table, gameType, billingType, pricingConfig) ??
              0.0;
          basePrice += (controllers - 1) * extraCharge;
        }
      }
    }

    final price = basePrice;

    if (price == null) {
      return const GameChargeBreakdown(
        baseCharge: 0,

        overtimeMinutes: 0,

        overtimeCharge: 0,
      );
    }

    double perSecondRate;
    if (billingType == BillingType.perMinute && customPrice != null) {
      perSecondRate = customPrice / 60.0;
    } else if (billingType == BillingType.customMinute && customPrice != null) {
      perSecondRate = customPrice / 60.0;
    } else if (tableType.isOtherGame && basePrice != null) {
      final perMinuteOption = table.billingOptions?['perMinute'];
      if (perMinuteOption != null && perMinuteOption.enabled && perMinuteOption.price > 0) {
        perSecondRate = perMinuteOption.price / 60.0;
      } else if (billingType == BillingType.halfHour) {
        perSecondRate = basePrice / (30 * 60.0);
      } else if (billingType == BillingType.oneHour) {
        perSecondRate = basePrice / (60 * 60.0);
      } else if (billingType == BillingType.oneHourThirty) {
        perSecondRate = basePrice / (90 * 60.0);
      } else {
        perSecondRate =
            getPerMinutePrice(table, gameType, pricingConfig) / 60.0;
      }
    } else {
      perSecondRate =
          getPerMinutePrice(table, gameType, pricingConfig) / 60.0;
    }

    final double overtimePerSecondRate =
        getOvertimePrice(table, gameType, pricingConfig) / 60.0;

    final bool tableOtDefault = isOvertimeConfiguredEnabled(table);
    final bool overtimeEnabled =
        isOvertimeEnabled ?? (tableOtDefault && gameConfig.enableOvertimeBilling);

    GameChargeBreakdown rawBreakdown;
    switch (billingType) {
      case BillingType.perCoin:
        rawBreakdown = GameChargeBreakdown(
          baseCharge: price * (coinQuantity ?? 1),
          overtimeMinutes: 0,
          overtimeCharge: 0,
        );

      case BillingType.perMinute:
        rawBreakdown = GameChargeBreakdown(
          baseCharge: activeSeconds * perSecondRate,
          overtimeMinutes: 0,
          overtimeCharge: 0,
        );

      case BillingType.customMinute:
        final int targetMinutes = customMinutes ?? 0;
        final int targetSeconds = targetMinutes * 60;
        final double perMinuteRate = (customPrice != null)
            ? customPrice
            : (perSecondRate * 60.0);
        final double rawBase = targetMinutes * perMinuteRate;
        final double customBaseCharge = BillingUtils.roundAmount(rawBase);
        
        final int elapsedOvertimeSeconds = activeSeconds - targetSeconds;
        final int overtimeMins = elapsedOvertimeSeconds > 0
            ? (elapsedOvertimeSeconds / 60.0).ceil()
            : 0;
            
        final double rawOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? elapsedOvertimeSeconds * overtimePerSecondRate
            : 0;

        final double finalOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? (BillingUtils.roundAmount(customBaseCharge + rawOvertimeCharge) - customBaseCharge)
            : 0.0;
            
        rawBreakdown = GameChargeBreakdown(
          baseCharge: customBaseCharge,
          overtimeMinutes: overtimeMins,
          overtimeCharge: finalOvertimeCharge,
        );

      case BillingType.perFrame:
        final baseCharge = framesPlayed * price;

        int totalOvertimeMinutes = completedRounds.fold<int>(
          0,
          (sum, r) => sum + (r.overtimeMinutes ?? 0),
        );

        double totalOvertimeCharge = completedRounds.fold<double>(
          0.0,
          (sum, r) => sum + (r.overtimeCharge ?? 0.0),
        );

        if (framesPlayed > completedRounds.length || completedRounds.isEmpty) {
          final int previousSeconds = completedRounds.fold<int>(
            0,
            (sum, r) => sum + (r.durationSeconds ?? 0),
          );

          final int currentFrameSeconds = (activeSeconds - previousSeconds)
              .clamp(0, 999999);

          int gracePeriodMinutes = 0;
          if (tableType == TableType.indianPool) {
            gracePeriodMinutes = gameConfig.indianPoolGracePeriodMinutes;
          } else if (tableType == TableType.americanPool) {
            gracePeriodMinutes = gameConfig.americanPoolGracePeriodMinutes;
          }
          final int currentOvertimeSeconds =
              currentFrameSeconds - (gracePeriodMinutes * 60);

          if (currentOvertimeSeconds > 0) {
            final int currentOvertimeMinutes = (currentOvertimeSeconds / 60.0)
                .ceil();

            totalOvertimeMinutes += currentOvertimeMinutes;

            if (overtimeEnabled) {
              final double currentOvertimeCharge =
                  currentOvertimeSeconds * overtimePerSecondRate;
              totalOvertimeCharge += currentOvertimeCharge;
            }
          }
        }

        if (!overtimeEnabled) {
          totalOvertimeCharge = 0.0;
        }

        rawBreakdown = GameChargeBreakdown(
          baseCharge: baseCharge,

          overtimeMinutes: totalOvertimeMinutes,

          overtimeCharge: totalOvertimeCharge,
        );

      case BillingType.halfHour:
        final int elapsedOvertimeSeconds = activeSeconds - (30 * 60);
        final int overtimeMinutes = elapsedOvertimeSeconds > 0
            ? (elapsedOvertimeSeconds / 60.0).ceil()
            : 0;

        final double rawOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? elapsedOvertimeSeconds * overtimePerSecondRate
            : 0;

        final double finalOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? (BillingUtils.roundAmount(price + rawOvertimeCharge) - price)
            : 0.0;

        rawBreakdown = GameChargeBreakdown(
          baseCharge: price,
          overtimeMinutes: overtimeMinutes,
          overtimeCharge: finalOvertimeCharge,
        );

      case BillingType.oneHour:
        final int elapsedOvertimeSeconds = activeSeconds - (60 * 60);
        final int overtimeMinutes = elapsedOvertimeSeconds > 0
            ? (elapsedOvertimeSeconds / 60.0).ceil()
            : 0;

        final double rawOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? elapsedOvertimeSeconds * overtimePerSecondRate
            : 0;

        final double finalOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? (BillingUtils.roundAmount(price + rawOvertimeCharge) - price)
            : 0.0;

        rawBreakdown = GameChargeBreakdown(
          baseCharge: price,
          overtimeMinutes: overtimeMinutes,
          overtimeCharge: finalOvertimeCharge,
        );

      case BillingType.oneHourThirty:
        final int elapsedOvertimeSeconds = activeSeconds - (90 * 60);
        final int overtimeMinutes = elapsedOvertimeSeconds > 0
            ? (elapsedOvertimeSeconds / 60.0).ceil()
            : 0;

        final double rawOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? elapsedOvertimeSeconds * overtimePerSecondRate
            : 0;

        final double finalOvertimeCharge = (elapsedOvertimeSeconds > 0 && overtimeEnabled)
            ? (BillingUtils.roundAmount(price + rawOvertimeCharge) - price)
            : 0.0;

        rawBreakdown = GameChargeBreakdown(
          baseCharge: price,
          overtimeMinutes: overtimeMinutes,
          overtimeCharge: finalOvertimeCharge,
        );
    }
    if (isMinimumBillEnabled && minimumBillAmount > 0) {
      if (tableType == TableType.snooker ||
          tableType == TableType.indianPool ||
          tableType == TableType.americanPool) {
        if (rawBreakdown.totalCharge < minimumBillAmount) {
          final diff = minimumBillAmount - rawBreakdown.totalCharge;
          return GameChargeBreakdown(
            baseCharge: rawBreakdown.baseCharge,
            overtimeMinutes: rawBreakdown.overtimeMinutes,
            overtimeCharge: rawBreakdown.overtimeCharge,
            minimumBillAdjustment: diff,
          );
        }
      }
    }
    return rawBreakdown;
  }
}
