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
    defaultMatchType = settings.game.defaultMatchType;
  }

  /// Returns the per minute price for a table type and game type (used for overtime).
  static double getPerMinutePrice(TableType tableType, GameType gameType, PricingSettings pricingConfig) {
    if (gameType == GameType.race) {
      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
        default: return pricingConfig.snookerRacePerMinute;
      }
    } else if (gameType == GameType.rummy && tableType == TableType.snooker) {
      return pricingConfig.snookerRummyPerMinute;
    }
    switch (tableType) {
      case TableType.snooker: return pricingConfig.snookerPerMinute;
      case TableType.indianPool: return pricingConfig.indianPoolPerMinute;
      case TableType.americanPool: return pricingConfig.americanPoolPerMinute;
      default: return pricingConfig.snookerPerMinute;
    }
  }

  /// Returns the price for a given table type, game type, and billing type.
  /// Returns null if the combination is not supported.
  static double? getPrice(TableType tableType, GameType gameType, BillingType billingType, PricingSettings pricingConfig) {
    if (gameType == GameType.race) {
      if (billingType != BillingType.perMinute) return null;
      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
        default: return pricingConfig.snookerRacePerMinute;
      }
    } else if (gameType == GameType.rummy) {
      if (billingType != BillingType.perMinute || tableType != TableType.snooker) return null;
      return pricingConfig.snookerRummyPerMinute;
    }

    switch (tableType) {
      case TableType.snooker:
        switch (billingType) {
          case BillingType.perMinute:
            return pricingConfig.snookerPerMinute;
          case BillingType.halfHour:
            return pricingConfig.snookerHalfHour;
          case BillingType.oneHour:
            return pricingConfig.snookerOneHour;
          case BillingType.perFrame:
            return null; // Snooker does not support per-frame
        }
      case TableType.indianPool:
        switch (billingType) {
          case BillingType.perFrame:
            return pricingConfig.indianPoolPerFrame;
          case BillingType.perMinute:
            return pricingConfig.indianPoolPerMinute; // Fixed: Indian Pool now supports per-minute
          case BillingType.halfHour:
            return pricingConfig.indianPoolHalfHour;
          case BillingType.oneHour:
            return pricingConfig.indianPoolOneHour;
        }
      case TableType.americanPool:
        switch (billingType) {
          case BillingType.perFrame:
            return pricingConfig.americanPoolPerFrame;
          case BillingType.perMinute:
            return pricingConfig.americanPoolPerMinute;
          case BillingType.halfHour:
            return pricingConfig.americanPoolHalfHour;
          case BillingType.oneHour:
            return pricingConfig.americanPoolOneHour;
        }
      case TableType.ps5:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.ps5HalfHour;
          case BillingType.oneHour: return pricingConfig.ps5OneHour;
          default: return null;
        }
      case TableType.pc:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.pcHalfHour;
          case BillingType.oneHour: return pricingConfig.pcOneHour;
          default: return null;
        }
      case TableType.carrom:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.carromHalfHour;
          case BillingType.oneHour: return pricingConfig.carromOneHour;
          default: return null;
        }
      case TableType.foosball:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.foosballHalfHour;
          case BillingType.oneHour: return pricingConfig.foosballOneHour;
          default: return null;
        }
      case TableType.chess:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.chessHalfHour;
          case BillingType.oneHour: return pricingConfig.chessOneHour;
          default: return null;
        }
      default:
        switch (billingType) {
          case BillingType.perMinute:
            return pricingConfig.snookerPerMinute;
          case BillingType.halfHour:
            return pricingConfig.snookerHalfHour;
          case BillingType.oneHour:
            return pricingConfig.snookerOneHour;
          case BillingType.perFrame:
            return null;
        }
    }
  }

  /// Returns all billing types supported by a given table type and game type.
  static List<BillingType> supportedBillingTypes(TableType tableType, GameType gameType) {
    if (gameType == GameType.race || gameType == GameType.rummy) {
      return [BillingType.perMinute];
    }
    switch (tableType) {
      case TableType.snooker:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      case TableType.indianPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour]; // Fixed: Indian pool now supports per-minute
      case TableType.americanPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      case TableType.ps5:
      case TableType.pc:
      case TableType.carrom:
      case TableType.foosball:
      case TableType.chess:
        return [BillingType.halfHour, BillingType.oneHour];
      default:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
    }
  }

  /// Calculate the game charge breakdown for a completed or active session.
  static GameChargeBreakdown calculateCharge({
    required TableType tableType,
    required GameType gameType,
    required BillingType billingType,
    required int activeSeconds,
    required int framesPlayed,
    required PricingSettings pricingConfig,
    required GameSettings gameConfig,
    List<GameRound> completedRounds = const [],
    double? customPrice,
  }) {
    final price = customPrice ?? getPrice(tableType, gameType, billingType, pricingConfig);
    if (price == null) {
      return const GameChargeBreakdown(
        baseCharge: 0,
        overtimeMinutes: 0,
        overtimeCharge: 0,
      );
    }

    final double perSecondRate = (customPrice ?? getPerMinutePrice(tableType, gameType, pricingConfig)) / 60.0;
    final bool overtimeEnabled = gameConfig.enableOvertimeBilling;

    switch (billingType) {
      case BillingType.perMinute:
        return GameChargeBreakdown(
          baseCharge: activeSeconds * perSecondRate,
          overtimeMinutes: 0,
          overtimeCharge: 0,
        );

      case BillingType.perFrame:
        final baseCharge = framesPlayed * price;
        int totalOvertimeMinutes = completedRounds.fold<int>(0, (sum, r) => sum + (r.overtimeMinutes ?? 0));
        double totalOvertimeCharge = completedRounds.fold<double>(0.0, (sum, r) => sum + (r.overtimeCharge ?? 0.0));

        if (framesPlayed > completedRounds.length || completedRounds.isEmpty) {
          final int previousSeconds = completedRounds.fold<int>(0, (sum, r) => sum + (r.durationSeconds ?? 0));
          final int currentFrameSeconds = (activeSeconds - previousSeconds).clamp(0, 999999);
          final int currentOvertimeSeconds = currentFrameSeconds - (gameConfig.frameGracePeriodMinutes * 60);
          if (currentOvertimeSeconds > 0 && overtimeEnabled) {
            final int currentOvertimeMinutes = (currentOvertimeSeconds / 60.0).ceil();
            final double currentOvertimeCharge = currentOvertimeSeconds * perSecondRate;
            totalOvertimeMinutes += currentOvertimeMinutes;
            totalOvertimeCharge += currentOvertimeCharge;
          }
        }

        if (!overtimeEnabled) {
          totalOvertimeMinutes = 0;
          totalOvertimeCharge = 0.0;
        }

        return GameChargeBreakdown(
          baseCharge: baseCharge,
          overtimeMinutes: totalOvertimeMinutes,
          overtimeCharge: totalOvertimeCharge,
        );
        
      case BillingType.halfHour:
        final int overtimeSeconds = overtimeEnabled ? (activeSeconds - (30 * 60)) : 0;
        final double overtimeCharge = overtimeSeconds > 0 ? overtimeSeconds * perSecondRate : 0;
        final int overtimeMinutes = overtimeSeconds > 0 ? (overtimeSeconds / 60.0).ceil() : 0;
        
        return GameChargeBreakdown(
          baseCharge: price,
          overtimeMinutes: overtimeMinutes,
          overtimeCharge: overtimeCharge,
        );
        
      case BillingType.oneHour:
        final int overtimeSeconds = overtimeEnabled ? (activeSeconds - (60 * 60)) : 0;
        final double overtimeCharge = overtimeSeconds > 0 ? overtimeSeconds * perSecondRate : 0;
        final int overtimeMinutes = overtimeSeconds > 0 ? (overtimeSeconds / 60.0).ceil() : 0;
        
        return GameChargeBreakdown(
          baseCharge: price,
          overtimeMinutes: overtimeMinutes,
          overtimeCharge: overtimeCharge,
        );
    }
  }
}
