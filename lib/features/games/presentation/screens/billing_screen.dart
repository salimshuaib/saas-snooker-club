import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final GameSession session;

  const BillingScreen({super.key, required this.session});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  late GameSession _session;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _winnerId;
  String? _PlayerProfileName;
  late Map<String, PaymentMethod> _playerPaymentMethods;
  late Map<String, double> _customLiabilities;
  bool _isProcessing = false;
  
  String? _raceSelectedWinnerTeam;
  String? _raceSelectedPayingPlayer;
  
  late TextEditingController _finalAmountController;
  bool _isFinalAmountInitialized = false;
  
  // Custom split
  final Map<String, double> _customSplit = {};

  @override
  void initState() {
    super.initState();
    _finalAmountController = TextEditingController();
    _session = widget.session.copyWith(endTime: DateTime.now());
    if (_session.matchType == MatchType.friendly) {
      _winnerId = null;
    }
    _playerPaymentMethods = {
      for (final p in _session.allPlayers) p: PaymentMethod.cash,
    };
    if (_session.gameType == GameType.race) {
      if (_session.mode == GameMode.team) {
        _raceSelectedWinnerTeam = 'Team A';
      } else if (_session.allPlayers.isNotEmpty) {
        // By default, the first player pays
        _raceSelectedPayingPlayer = _session.allPlayers.first;
      }
    }
    // Initialization of _customLiabilities will happen in didChangeDependencies
    // to safely access ref.read for pricing breakdown
  }

  @override
  void dispose() {
    _finalAmountController.dispose();
    super.dispose();
  }

  bool _liabilitiesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_liabilitiesInitialized) {
      _initializeLiabilities();
      _liabilitiesInitialized = true;
    }
  }

  void _initializeLiabilities() {
    final Map<String, double> liabilities = {
      for (final p in _session.allPlayers) p: 0.0,
    };

    final totalToSplit =
        _finalTotal; // _grandTotal uses _gameCharge + _ordersTotal

    if (_session.gameType == GameType.rummy) {
      // Rummy: Split evenly across all players
      final split =
          totalToSplit /
          (_session.allPlayers.isEmpty ? 1 : _session.allPlayers.length);
      for (final p in _session.allPlayers) {
        liabilities[p] = split;
      }
    } else if (_session.gameType == GameType.race) {
      if (_session.mode == GameMode.solo) {
        if (_raceSelectedPayingPlayer != null) {
          liabilities[_raceSelectedPayingPlayer!] = totalToSplit;
        }
      } else {
        if (_raceSelectedWinnerTeam != null) {
          final losingTeam = _raceSelectedWinnerTeam == 'Team A' ? _session.teamB : _session.teamA;
          if (losingTeam.isNotEmpty) {
            final split = totalToSplit / losingTeam.length;
            for (final p in losingTeam) {
              liabilities[p] = split;
            }
          }
        }
      }
    } else {
      // Standard / TP Logic
      if (_session.rounds.isNotEmpty) {
        for (final r in _session.rounds) {
          final roundTotal = r.roundCost + (r.overtimeCharge ?? 0.0);
          if (r.loser != null) {
            if (r.loser == 'Team A' && _session.teamA.isNotEmpty) {
              final split = roundTotal / _session.teamA.length;
              for (final p in _session.teamA) {
                liabilities[p] = (liabilities[p] ?? 0.0) + split;
              }
            } else if (r.loser == 'Team B' && _session.teamB.isNotEmpty) {
              final split = roundTotal / _session.teamB.length;
              for (final p in _session.teamB) {
                liabilities[p] = (liabilities[p] ?? 0.0) + split;
              }
            } else {
              liabilities[r.loser!] =
                  (liabilities[r.loser!] ?? 0.0) + roundTotal;
            }
          }
        }
      } else {
        final split =
            _gameCharge /
            (_session.allPlayers.isEmpty ? 1 : _session.allPlayers.length);
        for (final p in _session.allPlayers) {
          liabilities[p] = (liabilities[p] ?? 0.0) + split;
        }
      }

      for (final o in _session.orders) {
        if (o.playerName != null && liabilities.containsKey(o.playerName)) {
          liabilities[o.playerName!] =
              (liabilities[o.playerName!] ?? 0.0) + o.total;
        } else if (_session.allPlayers.isNotEmpty) {
          final split = o.total / _session.allPlayers.length;
          for (final p in _session.allPlayers) {
            liabilities[p] = (liabilities[p] ?? 0.0) + split;
          }
        }
      }

      final totalComputed = liabilities.values.fold<double>(
        0.0,
        (s, v) => s + v,
      );
      final diff = totalToSplit - totalComputed;
      if (diff.abs() > 0.01 && _session.allPlayers.isNotEmpty) {
        final adj = diff / _session.allPlayers.length;
        for (final p in _session.allPlayers) {
          liabilities[p] = (liabilities[p] ?? 0.0) + adj;
        }
      }
    }

    setState(() {
      _customLiabilities = liabilities;
    });
  }

  bool get _isMultiRoundTP =>
      _session.billingType == BillingType.perFrame &&
      _session.matchType == MatchType.loserPays;

  GameChargeBreakdown get _breakdown {
    final appSettings = ref.read(appSettingsProvider);
    return TablePricingConfig.calculateCharge(
      tableType: _session.tableType,
      gameType: _session.gameType,
      billingType: _session.billingType,
      activeSeconds: _session.activeSeconds,
      framesPlayed: math.max(_session.framesPlayed, _session.totalFrames),
      pricingConfig: _session.pricingSnapshot ?? appSettings.pricing,
      gameConfig: _session.gameSettingsSnapshot ?? appSettings.game,
      completedRounds: _session.rounds,
      customPrice: _session.customPrice,
    );
  }

  double get _gameCharge => _breakdown.totalCharge;
  double get _baseGameCharge => _breakdown.baseCharge;
  int get _overtimeMinutes => _breakdown.overtimeMinutes;
  double get _overtimeCharge => _breakdown.overtimeCharge;

  double get _ordersTotal =>
      _session.orders.fold<double>(0, (s, o) => s + o.total);

  double get _grandTotal => _gameCharge + _ordersTotal;
  
  double get _roundedTotal => (_grandTotal / 10).roundToDouble() * 10;
  
  double get _finalTotal {
    if (!_isFinalAmountInitialized) {
      _finalAmountController.text = _roundedTotal.toStringAsFixed(0);
      _isFinalAmountInitialized = true;
    }
    return double.tryParse(_finalAmountController.text) ?? _roundedTotal;
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
  }

  int get _activePayerCount {
    if ((_isMultiRoundTP || _session.gameType != GameType.standard)) {
      return _customLiabilities.values.where((v) => v > 0).length;
    }
    return _customLiabilities.values.where((v) => v > 0).length;
  }

  bool get _isMultiPayer => _activePayerCount > 1;

  bool get _hasCredit {
    if ((_isMultiRoundTP || _session.gameType != GameType.standard)) {
      return _playerPaymentMethods.entries.any(
        (e) =>
            e.value == PaymentMethod.credit &&
            (_customLiabilities[e.key] ?? 0) > 0,
      );
    }
    return _paymentMethod == PaymentMethod.credit;
  }

  String get _ctaLabel {
    if (_isMultiPayer) {
      return 'Mark Payment Complete';
    } else {
      if (_hasCredit) {
        return 'Record Payment & Credit';
      }
      return 'Confirm Payment (₹${_finalTotal.toStringAsFixed(0)})';
    }
  }

  Color get _ctaColor {
    if (_isMultiPayer) {
      return AppColors.primary;
    }
    return _hasCredit ? AppColors.creditStatus : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final currentSum = _customLiabilities.values.fold<double>(
      0.0,
      (s, v) => s + v,
    );
    final isBalanced = (_finalTotal - currentSum).abs() < 0.5;
    final theme = Theme.of(context);
    final dtFmt = DateFormat('d MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Bill'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Session Summary ──
            _SectionCard(
              children: [
                _InfoRow(label: 'Table', value: _session.tableName),
                _InfoRow(
                  label: 'Table Type',
                  value: _session.tableType.displayName,
                ),
                _InfoRow(
                  label: 'Game Type',
                  value: _session.gameType.displayName,
                ),
                _InfoRow(
                  label: 'Billing',
                  value: _session.billingType.displayName,
                ),
                _InfoRow(label: 'Match', value: _session.matchType.displayName),
                _InfoRow(
                  label: 'Mode',
                  value: _session.mode == GameMode.team ? 'Team' : 'Solo',
                ),
                _InfoRow(
                  label: 'Players',
                  value: _session.allPlayers.join(', '),
                ),
                _InfoRow(
                  label: 'Start Time',
                  value: dtFmt.format(_session.startTime),
                ),
                _InfoRow(
                  label: 'End Time',
                  value: dtFmt.format(_session.endTime!),
                ),
                _InfoRow(
                  label: 'Duration',
                  value: _formatDuration(_session.activeSeconds),
                ),
                if (_session.billingType == BillingType.perFrame)
                  _InfoRow(
                    label: 'Frames',
                    value:
                        '${_session.framesPlayed > 0 ? _session.framesPlayed : _session.totalFrames}',
                  ),
              ],
            ),
            const Gap(16),

            // ── Round / Frame Summary ──
            if (_session.rounds.isNotEmpty) ...[
              Text('Round / Frame Summary', style: theme.textTheme.titleMedium),
              const Gap(8),
              _SectionCard(
                children: [
                  ..._session.rounds.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r.winner == 'Friendly'
                                  ? 'Frame ${r.roundNumber} · ${(r.durationSeconds ?? 0) ~/ 60} mins${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}'
                                  : 'Round ${r.roundNumber} · Winner: ${r.winner == 'Team A'
                                        ? _session.teamA.join(' & ')
                                        : r.winner == 'Team B'
                                        ? _session.teamB.join(' & ')
                                        : (r.winner ?? "N/A")}${r.loser != null ? " · Loser: ${r.loser == 'Team A'
                                              ? _session.teamA.join(' & ')
                                              : r.loser == 'Team B'
                                              ? _session.teamB.join(' & ')
                                              : r.loser}" : ""}${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '₹${(r.roundCost + (r.overtimeCharge ?? 0.0)).toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
            ],

            // ── Winner Selection (Loser Pays non-multi round) ──
            if (!_isMultiRoundTP &&
                _session.gameType == GameType.standard &&
                _session.matchType == MatchType.loserPays) ...[
              Text('Select Winner', style: theme.textTheme.titleMedium),
              const Gap(8),
              _SectionCard(
                children: _session.mode == GameMode.team
                    ? [
                        _WinnerTile(
                          label: 'Team A (${_session.teamA.join(", ")})',
                          isSelected: _winnerId == 'Team A',
                          onTap: () => setState(() => _winnerId = 'Team A'),
                        ),
                        _WinnerTile(
                          label: 'Team B (${_session.teamB.join(", ")})',
                          isSelected: _winnerId == 'Team B',
                          onTap: () => setState(() => _winnerId = 'Team B'),
                        ),
                      ]
                    : _session.allPlayers
                          .map(
                            (p) => _WinnerTile(
                              label: p,
                              isSelected: _winnerId == p,
                              onTap: () => setState(() => _winnerId = p),
                            ),
                          )
                          .toList(),
              ),
              const Gap(16),
            ],

            // ── Race Winner Selection ──
            if (_session.gameType == GameType.race) ...[
              Text(
                _session.mode == GameMode.team ? 'Who Won?' : 'Who Will Pay?',
                style: theme.textTheme.titleMedium,
              ),
              const Gap(8),
              _SectionCard(
                children: _session.mode == GameMode.team
                    ? [
                        _WinnerTile(
                          label: 'Team A (${_session.teamA.join(", ")})',
                          isSelected: _raceSelectedWinnerTeam == 'Team A',
                          onTap: () {
                            setState(() => _raceSelectedWinnerTeam = 'Team A');
                            _initializeLiabilities();
                          },
                        ),
                        _WinnerTile(
                          label: 'Team B (${_session.teamB.join(", ")})',
                          isSelected: _raceSelectedWinnerTeam == 'Team B',
                          onTap: () {
                            setState(() => _raceSelectedWinnerTeam = 'Team B');
                            _initializeLiabilities();
                          },
                        ),
                      ]
                    : _session.allPlayers
                          .map(
                            (p) => _WinnerTile(
                              label: p,
                              isSelected: _raceSelectedPayingPlayer == p,
                              onTap: () {
                                setState(() => _raceSelectedPayingPlayer = p);
                                _initializeLiabilities();
                              },
                            ),
                          )
                          .toList(),
              ),
              const Gap(16),
            ],

            // ── Orders ──
            if (_session.orders.isNotEmpty) ...[
              Text('Orders', style: theme.textTheme.titleMedium),
              const Gap(8),
              _SectionCard(
                children: [
                  ..._session.orders.map(
                    (o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${o.quantity}x ${o.productName}${o.playerName != null ? ' (${o.playerName})' : ''}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '₹${o.total.toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
            ],

            // ── Bill Summary ──
            Text('Bill Summary', style: theme.textTheme.titleMedium),
            const Gap(8),
            _SectionCard(
              children: [
                if (_session.billingType == BillingType.perFrame) ...[
                  _InfoRow(
                    label: 'Frame Charges',
                    value: '₹${_baseGameCharge.toStringAsFixed(2)}',
                  ),
                  _InfoRow(
                    label: 'Grace Period',
                    value:
                        '${TablePricingConfig.frameGracePeriodMinutes} Mins / Frame',
                  ),
                ] else ...[
                  if (_session.billingType == BillingType.perMinute)
                    _InfoRow(
                      label: 'Rate',
                      value: '₹${(_session.customPrice ?? TablePricingConfig.getPerMinutePrice(_session.tableType, _session.gameType, _session.pricingSnapshot ?? appSettings.pricing)).toStringAsFixed(2)} / min',
                    ),
                  _InfoRow(
                    label: 'Base Charge',
                    value: '₹${_baseGameCharge.toStringAsFixed(2)}',
                  ),
                ],
                if (_overtimeMinutes > 0) ...[
                  _InfoRow(
                    label: 'Overtime (${_overtimeMinutes} mins)',
                    value: '₹${_overtimeCharge.toStringAsFixed(2)}',
                  ),
                ],
                const Divider(height: 16),
                _InfoRow(
                  label: 'Total Game Charge',
                  value: '₹${_gameCharge.toStringAsFixed(2)}',
                ),
                if (_ordersTotal > 0)
                  _InfoRow(
                    label: 'Orders Total',
                    value: '₹${_ordersTotal.toStringAsFixed(2)}',
                  ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Calculated Total',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '₹${_grandTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Final Bill Amount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _finalAmountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            prefixText: '₹',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _customSplit.clear();
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Gap(16),

            // ── Payment Method & Liability Distribution ──
            if (_isMultiRoundTP || _session.gameType != GameType.standard) ...[
              Text(
                'Player Liabilities & Payment',
                style: theme.textTheme.titleMedium,
              ),
              const Gap(8),
              _buildSplitLiabilityTable(theme),
              const Gap(32),
            ] else ...[
              Text('Payment Method', style: theme.textTheme.titleMedium),
              const Gap(8),
              Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _paymentMethod == method;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMethod = method),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: method != PaymentMethod.credit ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              _paymentIcon(method),
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const Gap(4),
                            Text(
                              method.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_paymentMethod == PaymentMethod.credit) ...[
                const Gap(24),
                Text(
                  'Select Customer for Credit',
                  style: theme.textTheme.titleMedium,
                ),
                const Gap(8),
                _SectionCard(
                  children: _session.allPlayers
                      .map(
                        (p) => _WinnerTile(
                          label: p,
                          isSelected: _PlayerProfileName == p,
                          onTap: () => setState(() => _PlayerProfileName = p),
                        ),
                      )
                      .toList(),
                ),
              ],
              const Gap(32),
            ],

            // ── Confirm Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    (_isProcessing ||
                        (_isMultiRoundTP ||
                                _session.gameType != GameType.standard) &&
                            !isBalanced)
                    ? null
                    : _confirmPayment,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _ctaColor,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _ctaLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitLiabilityTable(ThemeData theme) {
    final liabilities = _customLiabilities;
    final players = _session.allPlayers;

    // Sum validation
    final currentSum = liabilities.values.fold<double>(0.0, (s, v) => s + v);
    final diff = (_finalTotal - currentSum).abs();
    final isBalanced = diff < 0.5; // Small tolerance

    return Column(
      children: [
        if (!isBalanced)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Split amounts (₹) do not equal the grand total (₹).',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _SectionCard(
          children: players.map((player) {
            final amount = liabilities[player] ?? 0.0;
            final selectedMethod =
                _playerPaymentMethods[player] ?? PaymentMethod.cash;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        player,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          initialValue: amount == 0
                              ? '0'
                              : amount.toStringAsFixed(
                                  amount.truncateToDouble() == amount ? 0 : 2,
                                ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.currency_rupee,
                              size: 16,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _customLiabilities[player] =
                                  double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: PaymentMethod.values.map((method) {
                      final isSelected = selectedMethod == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _playerPaymentMethods[player] = method,
                          ),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: method != PaymentMethod.credit ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _paymentIcon(method),
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const Gap(4),
                                Text(
                                  method.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (player != players.last) const Divider(height: 24),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.upi:
        return Icons.qr_code_scanner;
      case PaymentMethod.credit:
        return Icons.credit_score;
    }
  }

  Future<void> _confirmPayment() async {
    if (_isProcessing) return;
    if (!_isMultiRoundTP &&
        _session.gameType == GameType.standard &&
        _session.matchType == MatchType.loserPays &&
        _winnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a winner before confirming payment.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_isMultiRoundTP &&
        _session.gameType == GameType.standard &&
        _paymentMethod == PaymentMethod.credit &&
        _PlayerProfileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer taking the credit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final finalEndTime = _session.isManualEntry
        ? _session.endTime!
        : DateTime.now();
    final finalDate = DateFormat('yyyy-MM-dd').format(finalEndTime);

    final finalSession =
        (_isMultiRoundTP || _session.gameType != GameType.standard)
        ? _session.copyWith(
            endTime: finalEndTime,
            status: TableStatus.available,
            playerPaymentMethods: _playerPaymentMethods,
            playerLiabilities: _customLiabilities,
            gameCharge: _gameCharge,
            baseGameCharge: _baseGameCharge,
            overtimeMinutes: _overtimeMinutes,
            overtimeCharge: _overtimeCharge,
            ordersTotal: _ordersTotal,
            grandTotal: _grandTotal,
            roundedAmount: _roundedTotal,
            finalAmount: _finalTotal,
            date: finalDate,
          )
        : _session.copyWith(
            endTime: finalEndTime,
            status: TableStatus.available,
            winnerId: _winnerId,
            paidBy: _paymentMethod == PaymentMethod.credit
                ? _PlayerProfileName
                : null,
            paymentMethod: _paymentMethod,
            gameCharge: _gameCharge,
            baseGameCharge: _baseGameCharge,
            overtimeMinutes: _overtimeMinutes,
            overtimeCharge: _overtimeCharge,
            ordersTotal: _ordersTotal,
            grandTotal: _grandTotal,
            roundedAmount: _roundedTotal,
            finalAmount: _finalTotal,
            date: finalDate,
          );

    try {
      await ref
          .read(gameSessionControllerProvider.notifier)
          .endGame(finalSession);
      if (mounted) {
        context.go('/games');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded. Table is now available.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WinnerTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.success, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.emoji_events : Icons.person_outline,
              color: isSelected
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? AppColors.success
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
