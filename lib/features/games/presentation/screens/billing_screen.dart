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
import 'package:snooker_club/features/games/presentation/widgets/payer_selection_widget.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final GameSession session;

  const BillingScreen({super.key, required this.session});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  late GameSession _session;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _PlayerProfileName;
  late Map<String, PaymentMethod> _playerPaymentMethods;
  late Map<String, double> _customLiabilities;
  bool _isProcessing = false;
  
  late List<String> _selectedPayers;
  double _discountAmount = 0.0;
  bool _hasDiscount = false;
  
  late TextEditingController _discountController;
  late TextEditingController _discountPercentController;
  
  final Map<String, TextEditingController> _liabilityControllers = {};

  bool _liabilitiesInitialized = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session.copyWith(endTime: DateTime.now());
    _selectedPayers = List.from(_session.selectedPayers ?? _session.allPlayers);
    _discountAmount = _session.discountAmount ?? 0.0;
    _hasDiscount = _discountAmount > 0;
    
    _discountController = TextEditingController(text: _discountAmount == 0 ? '' : _discountAmount.toStringAsFixed(0));
    // Calculate initial percent if amount exists
    double initialPercent = 0.0;
    // We cannot use _gameCharge here because it requires context for appSettings,
    // so we will just initialize empty and let the UI handle it or we can calculate base.
    _discountPercentController = TextEditingController();
    
    _playerPaymentMethods = {
      for (final p in _session.allPlayers) p: PaymentMethod.cash,
    };
  }

  @override
  void dispose() {
    _discountController.dispose();
    _discountPercentController.dispose();
    for (final c in _liabilityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }


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

    if (_session.allPlayers.isEmpty) return;

    final double discountedGame = _gameCharge - _discountAmount;

    if (_selectedPayers.isNotEmpty) {
      final rawShare = discountedGame / _selectedPayers.length;
      final roundedShare = (rawShare / 10).roundToDouble() * 10;
      
      for (final p in _selectedPayers) {
        liabilities[p] = roundedShare;
      }
    }

    for (final o in _session.orders) {
      if (o.playerName != null && liabilities.containsKey(o.playerName)) {
        liabilities[o.playerName!] = (liabilities[o.playerName!] ?? 0.0) + o.total;
      } else {
        final split = o.total / _session.allPlayers.length;
        for (final p in _session.allPlayers) {
          liabilities[p] = (liabilities[p] ?? 0.0) + split;
        }
      }
    }

    for (final p in _session.allPlayers) {
      final amount = liabilities[p] ?? 0.0;
      final textValue = amount == 0
          ? '0'
          : amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
          
      if (!_liabilityControllers.containsKey(p)) {
        _liabilityControllers[p] = TextEditingController(text: textValue);
      } else if (_liabilityControllers[p]!.text != textValue) {
        _liabilityControllers[p]!.text = textValue;
      }
    }

    setState(() {
      _customLiabilities = liabilities;
    });
  }

  bool get _isMultiPayer => _selectedPayers.length > 1 || (_selectedPayers.isEmpty && _session.allPlayers.length > 1);

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
      customExtraCharge: _session.customExtraCharge,
      playersCount: _session.playerIds.length,
      coinQuantity: _session.coinQuantity,
    );
  }

  double get _gameCharge => _breakdown.totalCharge;
  double get _baseGameCharge => _breakdown.baseCharge;
  int get _overtimeMinutes => _breakdown.overtimeMinutes;
  double get _overtimeCharge => _breakdown.overtimeCharge;

  double get _ordersTotal => _session.orders.fold<double>(0, (s, o) => s + o.total);

  double get _discountedGameCharge => _gameCharge - _discountAmount;

  double get _grandTotal => _gameCharge + _ordersTotal;
  
  double get _finalTotal => _discountedGameCharge + _ordersTotal;

  double get _roundedTotal {
    if (_session.tableType == TableType.arcade) {
      return _finalTotal;
    }
    if (_isMultiPayer) {
      if (_selectedPayers.isEmpty) return _finalTotal;
      final rawShare = _discountedGameCharge / _selectedPayers.length;
      final roundedShare = (rawShare / 10).roundToDouble() * 10;
      return (roundedShare * _selectedPayers.length) + _ordersTotal;
    }
    return (_finalTotal / 10).roundToDouble() * 10;
  }
  
  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
  }

  int get _activePayerCount {
    if ((_isMultiPayer || _session.gameType != GameType.standard)) {
      return _customLiabilities.values.where((v) => v > 0).length;
    }
    return _customLiabilities.values.where((v) => v > 0).length;
  }


  bool get _hasCredit {
    if ((_isMultiPayer || _session.gameType != GameType.standard)) {
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
      return 'Confirm Payment (\u20B9${_finalTotal.toStringAsFixed(0)})';
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
    final appSettings = ref.watch(appSettingsProvider);
    final currentSum = _customLiabilities.values.fold<double>(
      0.0,
      (s, v) => s + v,
    );
    final isBalanced = (_roundedTotal - currentSum).abs() < 0.5;
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

            // ── Round ── Frame Summary ──
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
                              r.framePayers == null
                                  ? 'Frame ${r.roundNumber} · ${(r.durationSeconds ?? 0) ~/ 60} mins${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}'
                                  : 'Frame ${r.roundNumber} · Payers: ${r.framePayers!.join(', ')}${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '\u20B9${(r.roundCost + (r.overtimeCharge ?? 0.0)).toStringAsFixed(2)}',
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

            // ── Payer Selection ──
            if (_session.allPlayers.isNotEmpty) ...[
              PayerSelectionWidget(
                allPlayers: _session.allPlayers,
                selectedPayers: _selectedPayers,
                onChanged: (newPayers) {
                  setState(() {
                    _selectedPayers = newPayers;
                  });
                  _initializeLiabilities();
                },
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
                            '\u20B9${o.total.toStringAsFixed(0)}',
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
                    value: '\u20B9${_baseGameCharge.toStringAsFixed(2)}',
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
                      value: '\u20B9${(_session.customPrice ?? TablePricingConfig.getPerMinutePrice(_session.tableType, _session.gameType, _session.pricingSnapshot ?? appSettings.pricing)).toStringAsFixed(2)} / min',
                    ),
                  _InfoRow(
                    label: 'Base Charge',
                    value: '\u20B9${_baseGameCharge.toStringAsFixed(2)}',
                  ),
                ],
                if (_overtimeMinutes > 0) ...[
                  _InfoRow(
                    label: 'Overtime (${_overtimeMinutes} mins)',
                    value: '\u20B9${_overtimeCharge.toStringAsFixed(2)}',
                  ),
                ],
                const Divider(height: 16),
                _InfoRow(
                  label: 'Total Game Charge',
                  value: '\u20B9${_gameCharge.toStringAsFixed(2)}',
                ),
                if (_ordersTotal > 0)
                  _InfoRow(
                    label: 'Orders Total',
                    value: '\u20B9${_ordersTotal.toStringAsFixed(2)}',
                  ),
                  // ── Discount ──
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Apply Discount', style: theme.textTheme.titleSmall),
                      Switch(
                        value: _hasDiscount,
                        onChanged: (val) {
                          setState(() {
                            _hasDiscount = val;
                            if (!val) {
                              _discountAmount = 0.0;
                              _discountPercentController.clear();
                              _discountController.clear();
                              _initializeLiabilities();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_hasDiscount) ...[
                    const Gap(12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountPercentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Percentage',
                              suffixText: '%',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (val) {
                              final percent = double.tryParse(val) ?? 0.0;
                              final amount = (_gameCharge * (percent / 100));
                              setState(() {
                                _discountAmount = amount;
                                _discountController.text = amount == 0 ? '' : amount.toStringAsFixed(0);
                              });
                              _initializeLiabilities();
                            },
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '\u20B9',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (val) {
                              final amount = double.tryParse(val) ?? 0.0;
                              final percent = _gameCharge > 0 ? (amount / _gameCharge) * 100 : 0.0;
                              setState(() {
                                _discountAmount = amount;
                                _discountPercentController.text = percent == 0 ? '' : percent.toStringAsFixed(1);
                              });
                              _initializeLiabilities();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  
                  // ── Final Amounts ──
                  if (_hasDiscount) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discounted Game', style: theme.textTheme.titleSmall),
                        Text('\u20B9${_discountedGameCharge.toStringAsFixed(2)}', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const Gap(4),
                  ],
                  if (_ordersTotal > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Orders', style: theme.textTheme.titleSmall),
                        Text('\u20B9${_ordersTotal.toStringAsFixed(2)}', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const Gap(12),
                  ] else if (!_hasDiscount) ...[
                    // Add a small gap if both are hidden so the divider doesn't look too close
                    const Gap(8),
                  ],
                  if ((_roundedTotal - _finalTotal).abs() > 0.01) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rounding Adjustment', style: theme.textTheme.titleSmall),
                        Text('${(_roundedTotal - _finalTotal) > 0 ? '+' : '-'}\u20B9${(_roundedTotal - _finalTotal).abs().toStringAsFixed(2)}', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const Gap(12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Final Bill Amount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        '\u20B9${_roundedTotal.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Gap(16),

            // ── Payment Method ── Liability Distribution ──
            if (_isMultiPayer) ...[
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
                        (_isMultiPayer ||
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
    final diff = (_roundedTotal - currentSum).abs();
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
                    'Split amounts (\u20B9) do not equal the grand total (\u20B9).',
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
                          controller: _liabilityControllers[player],
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


    if (!_isMultiPayer &&
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
        (_isMultiPayer || _session.gameType != GameType.standard)
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
