import 'package:snooker_club/features/games/domain/models/game_models.dart';

import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

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
      String? key;
      if (gameType == GameType.race) {
        key = 'racePerMinute';
      } else if (gameType == GameType.rummy) {
        key = 'rummyPerMinute';
      } else {
        key = 'perMinute';
      }
      final option = table.billingOptions![key];
      if (option != null && option.enabled) {
        return option.price;
      }
    }
    if (gameType == GameType.race) {
      switch (tableType) {
        case TableType.snooker:
          return pricingConfig.snookerRacePerMinute;

        case TableType.indianPool:
          return pricingConfig.indianPoolRacePerMinute;

        case TableType.americanPool:
          return pricingConfig.americanPoolRacePerMinute;

        default:
          return pricingConfig.snookerRacePerMinute;
      }
    } else if (gameType == GameType.rummy && tableType == TableType.snooker) {
      return pricingConfig.snookerRummyPerMinute;
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
      case TableType.arcade:
        return 0.0; // Arcade games do not use overtime
      default:
        return pricingConfig.snookerPerMinute;
    }
  }

  /// Returns the price for a given table type, game type, and billing type.

  /// Returns null if the combination is not supported.

  static double? getExtraCharge(
    TableModel table,
    GameType gameType,
    BillingType billingType,
    PricingSettings fallbackConfig,
  ) {
    if (table.type != TableType.ps5 && table.type != TableType.ps4) return 0.0;

    if (table.billingOptions != null) {
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
    return 0.0;
  }

  static double? getPrice(
    TableModel table,
    GameType gameType,
    BillingType billingType,
    PricingSettings fallbackConfig,
  ) {
    // If the table has specific billing options configured

    if (table.billingOptions != null) {
      String? key;

      if (gameType == GameType.race && billingType == BillingType.perMinute) {
        key = 'racePerMinute';
      } else if (gameType == GameType.rummy &&
          billingType == BillingType.perMinute) {
        key = 'rummyPerMinute';
      } else if (billingType == BillingType.customMinute) {
        key = 'perMinute';
      } else {
        key =
            billingType.name; // 'perMinute', 'halfHour', 'oneHour', 'perFrame'
      }

      final option = table.billingOptions![key];

      if (option != null && option.enabled) {
        return option.price;
      }

      return null; // Explicitly configured but disabled or missing
    }

    // Fallback to legacy global logic

    final tableType = table.type;

    if (gameType == GameType.race) {
      if (billingType != BillingType.perMinute) return null;

      switch (tableType) {
        case TableType.snooker:
          return fallbackConfig.snookerRacePerMinute;

        case TableType.indianPool:
          return fallbackConfig.indianPoolRacePerMinute;

        case TableType.americanPool:
          return fallbackConfig.americanPoolRacePerMinute;

        default:
          return fallbackConfig.snookerRacePerMinute;
      }
    } else if (gameType == GameType.rummy) {
      if (billingType != BillingType.perMinute ||
          tableType != TableType.snooker)
        return null;

      return fallbackConfig.snookerRummyPerMinute;
    }

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
          case BillingType.halfHour:
            return fallbackConfig.ps5HalfHour;

          case BillingType.oneHour:
            return fallbackConfig.ps5OneHour;

          default:
            return null;
        }

      case TableType.pc:
        switch (billingType) {
          case BillingType.halfHour:
            return fallbackConfig.pcHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.pcOneHour;

          default:
            return null;
        }

      case TableType.carrom:
        switch (billingType) {
          case BillingType.halfHour:
            return fallbackConfig.carromHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.carromOneHour;

          default:
            return null;
        }

      case TableType.foosball:
        switch (billingType) {
          case BillingType.halfHour:
            return fallbackConfig.foosballHalfHour;

          case BillingType.oneHour:
            return fallbackConfig.foosballOneHour;

          default:
            return null;
        }

      case TableType.chess:
        switch (billingType) {
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
          case BillingType.halfHour:
            return fallbackConfig.chessHalfHour;
          case BillingType.oneHour:
            return fallbackConfig.chessOneHour;
          default:
            return null;
        }

      case TableType.ps4:
        switch (billingType) {
          case BillingType.halfHour:
            return fallbackConfig.ps4HalfHour;
          case BillingType.oneHour:
            return fallbackConfig.ps4OneHour;
          default:
            return null;
        }

      case TableType.simulator:
        switch (billingType) {
          case BillingType.halfHour:
            return fallbackConfig.simulatorHalfHour;
          case BillingType.oneHour:
            return fallbackConfig.simulatorOneHour;
          default:
            return null;
        }

      case TableType.iceHockey:
        switch (billingType) {
          case BillingType.halfHour:
            return fallbackConfig.iceHockeyHalfHour;
          case BillingType.oneHour:
            return fallbackConfig.iceHockeyOneHour;
          default:
            return null;
        }

      case TableType.arcade:
        if (billingType == BillingType.perCoin)
          return fallbackConfig.arcadeCoinPrice;
        return null;

      default:
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
    }
  }

  /// Returns all billing types supported by a given table type and game type.

  static List<BillingType> supportedBillingTypes(
    TableModel table,
    GameType gameType,
  ) {
    final types = _supportedBillingTypesInternal(table, gameType);
    final isConsole = table.type == TableType.ps4 || table.type == TableType.ps5;
    
    // Convert to modifiable list if it isn't
    final List<BillingType> result = List.from(types);
    
    if (!isConsole && !result.contains(BillingType.customMinute)) {
      result.add(BillingType.customMinute);
    }
    
    return result;
  }

  static List<BillingType> _supportedBillingTypesInternal(
    TableModel table,
    GameType gameType,
  ) {
    if (table.billingOptions != null) {
      final List<BillingType> types = [];

      if (gameType == GameType.race) {
        if (table.billingOptions!['racePerMinute']?.enabled == true) {
          types.add(BillingType.perMinute);
        }

        return types;
      } else if (gameType == GameType.rummy) {
        if (table.billingOptions!['rummyPerMinute']?.enabled == true) {
          types.add(BillingType.perMinute);
        }

        return types;
      }

      if (table.billingOptions!['perMinute']?.enabled == true)
        types.add(BillingType.perMinute);

      if (table.billingOptions!['perFrame']?.enabled == true)
        types.add(BillingType.perFrame);

      if (table.billingOptions!['halfHour']?.enabled == true)
        types.add(BillingType.halfHour);

      if (table.billingOptions!['oneHour']?.enabled == true)
        types.add(BillingType.oneHour);
      if (table.billingOptions!['perCoin']?.enabled == true)
        types.add(BillingType.perCoin);

      return types;
    }

    // Fallback logic

    final tableType = table.type;

    if (gameType == GameType.race || gameType == GameType.rummy) {
      return [BillingType.perMinute];
    }

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
        return [BillingType.perCoin];

      default:
        return [
          BillingType.perMinute,
          BillingType.halfHour,
          BillingType.oneHour,
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
  }) {
    final tableType = table.type;

    double? basePrice =
        customPrice ??
        getPrice(table, gameType, billingType, pricingConfig);

    if (basePrice != null &&
        (tableType == TableType.ps5 || tableType == TableType.ps4)) {
      final controllers = (playersCount != null && playersCount > 0)
          ? playersCount
          : 1;
      if (controllers > 1) {
        final extraCharge =
            customExtraCharge ??
            getExtraCharge(table, gameType, billingType, pricingConfig) ??
            0.0;
        basePrice += (controllers - 1) * extraCharge;
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
    } else if (tableType.isOtherGame && basePrice != null) {
      if (billingType == BillingType.halfHour) {
        perSecondRate = basePrice / (30 * 60.0);
      } else if (billingType == BillingType.oneHour) {
        perSecondRate = basePrice / (60 * 60.0);
      } else {
        perSecondRate =
            getPerMinutePrice(table, gameType, pricingConfig) / 60.0;
      }
    } else {
      perSecondRate =
          getPerMinutePrice(table, gameType, pricingConfig) / 60.0;
    }

    final bool overtimeEnabled = gameConfig.enableOvertimeBilling;

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
        final double customBaseCharge = targetMinutes * perSecondRate * 60.0;
        
        final int overtimeSeconds = overtimeEnabled
            ? (activeSeconds - targetSeconds)
            : 0;
            
        final double overtimeCharge = overtimeSeconds > 0
            ? overtimeSeconds * perSecondRate
            : 0;
            
        final int overtimeMins = overtimeSeconds > 0
            ? (overtimeSeconds / 60.0).ceil()
            : 0;
            
        rawBreakdown = GameChargeBreakdown(
          baseCharge: customBaseCharge,
          overtimeMinutes: overtimeMins,
          overtimeCharge: overtimeCharge,
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

          if (currentOvertimeSeconds > 0 && overtimeEnabled) {
            final int currentOvertimeMinutes = (currentOvertimeSeconds / 60.0)
                .ceil();

            final double currentOvertimeCharge =
                currentOvertimeSeconds * perSecondRate;

            totalOvertimeMinutes += currentOvertimeMinutes;

            totalOvertimeCharge += currentOvertimeCharge;
          }
        }

        if (!overtimeEnabled) {
          totalOvertimeMinutes = 0;

          totalOvertimeCharge = 0.0;
        }

        rawBreakdown = GameChargeBreakdown(
          baseCharge: baseCharge,

          overtimeMinutes: totalOvertimeMinutes,

          overtimeCharge: totalOvertimeCharge,
        );

      case BillingType.halfHour:
        final int overtimeSeconds = overtimeEnabled
            ? (activeSeconds - (30 * 60))
            : 0;

        final double overtimeCharge = overtimeSeconds > 0
            ? overtimeSeconds * perSecondRate
            : 0;

        final int overtimeMinutes = overtimeSeconds > 0
            ? (overtimeSeconds / 60.0).ceil()
            : 0;

        rawBreakdown = GameChargeBreakdown(
          baseCharge: price,

          overtimeMinutes: overtimeMinutes,

          overtimeCharge: overtimeCharge,
        );

      case BillingType.oneHour:
        final int overtimeSeconds = overtimeEnabled
            ? (activeSeconds - (60 * 60))
            : 0;

        final double overtimeCharge = overtimeSeconds > 0
            ? overtimeSeconds * perSecondRate
            : 0;

        final int overtimeMinutes = overtimeSeconds > 0
            ? (overtimeSeconds / 60.0).ceil()
            : 0;

        rawBreakdown = GameChargeBreakdown(
          baseCharge: price,

          overtimeMinutes: overtimeMinutes,

          overtimeCharge: overtimeCharge,
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
