import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/core/utils/billing_utils.dart';

import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/payer_selection_widget.dart';
import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';

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
  late Map<String, Map<PaymentMethod, double>> _playerPaymentSplits;
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

    _discountController = TextEditingController(
      text: _discountAmount == 0 ? '' : _discountAmount.toStringAsFixed(0),
    );
    // Calculate initial percent if amount exists
    double initialPercent = 0.0;
    // We cannot use _gameCharge here because it requires context for appSettings,
    // so we will just initialize empty and let the UI handle it or we can calculate base.
    _discountPercentController = TextEditingController();

    _playerPaymentSplits = {
      for (final p in _session.allPlayers) p: {PaymentMethod.cash: 0.0},
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

  void _showAddPlayerDialog() {
    PlayerSelection? newPlayerSelection;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Player to Bill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerSearchField(
                hint: 'Player Name',
                onSelected: (sel) {
                  newPlayerSelection = sel;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = newPlayerSelection?.name.trim();
                if (name != null && name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((playerName) {
      if (playerName != null && playerName is String) {
        setState(() {
          final newTeamA = List<String>.from(_session.teamA)..add(playerName);
          _session = _session.copyWith(teamA: newTeamA);

          if (!_selectedPayers.contains(playerName)) {
            _selectedPayers.add(playerName);
          }

          _playerPaymentSplits[playerName] = {PaymentMethod.cash: 0.0};
          _liabilityControllers[playerName] = TextEditingController();

          _initializeLiabilities();
        });
      }
    });
  }

  void _initializeLiabilities() {
    final Map<String, double> liabilities = {
      for (final p in _session.allPlayers) p: 0.0,
    };

    if (_session.allPlayers.isEmpty) {
      setState(() => _customLiabilities = liabilities);
      return;
    }

    final double discountedGame = _gameCharge - _discountAmount;

    if (_selectedPayers.isNotEmpty) {
      final rawShare = discountedGame / _selectedPayers.length;
      final roundedShare = BillingUtils.roundAmount(rawShare);

      for (final p in _selectedPayers) {
        liabilities[p] = roundedShare;
      }
    }

    for (final o in _session.orders) {
      if (o.playerName != null && liabilities.containsKey(o.playerName)) {
        liabilities[o.playerName!] =
            (liabilities[o.playerName!] ?? 0.0) + o.total;
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
      for (final p in _session.allPlayers) {
        final amount = liabilities[p] ?? 0.0;
        final currentSplits =
            _playerPaymentSplits[p] ?? {PaymentMethod.cash: amount};
        if (currentSplits.length == 1) {
          _playerPaymentSplits[p] = {currentSplits.keys.first: amount};
        } else {
          _playerPaymentSplits[p] = {PaymentMethod.cash: amount};
        }
      }
    });
  }

  bool get _isMultiPayer =>
      _selectedPayers.length > 1 ||
      (_selectedPayers.isEmpty && _session.allPlayers.length > 1);

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
      isMinimumBillEnabled: _session.isMinimumBillEnabled,
      minimumBillAmount: _session.minimumBillAmount,
    );
  }

  double get _gameCharge => _breakdown.totalCharge;
  double get _baseGameCharge => _breakdown.baseCharge;
  int get _overtimeMinutes => _breakdown.overtimeMinutes;
  double get _overtimeCharge => _breakdown.overtimeCharge;

  double get _ordersTotal =>
      _session.orders.fold<double>(0, (s, o) => s + o.total);

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
      final roundedShare = BillingUtils.roundAmount(rawShare);
      return (roundedShare * _selectedPayers.length) + _ordersTotal;
    }
    return BillingUtils.roundAmount(_finalTotal);
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
      return _playerPaymentSplits.entries.any(
        (e) => (e.value[PaymentMethod.credit] ?? 0.0) > 0.0,
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

  // ---- Colors ---------------------------------------------------------------
  static const _bg = Color(0xFF0B0D14);
  static const _card = Color(0xFF12141F);
  static const _chipBg = Color(0xFF1A1D29);
  static const _accent = Color(0xFF6C6FEF);
  static const _accentTint = Color(0x1F6C6FEF); // ~12% accent
  static const _textPrimary = Color(0xFFF4F5F8);
  static const _textSecondary = Color(0xFF8B8EA3);
  static const _textChip = Color(0xFFC9CBE0);
  static final _border = Colors.white.withOpacity(0.06);
  static final _radioBorder = Colors.white.withOpacity(0.2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: const BackButton(color: _textPrimary),
        title: const Text(
          'Bill',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildSessionCard(),
            const SizedBox(height: 16),
            _buildWhoPaysSection(),
            if (_session.orders.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildOrdersSection(),
            ],
            const SizedBox(height: 16),
            _buildBillSummaryCard(),
            const SizedBox(height: 16),
            _buildPaymentMethodSection(),
            const SizedBox(height: 16),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard() {
    final dtFmt = DateFormat('hh:mm a');
    final rateStr = _session.billingType == BillingType.perFrame
        ? 'Per Frame'
        : '₹${_baseGameCharge.toStringAsFixed(0)} / hr';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _session.tableName,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_session.tableType.displayName} table',
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rateStr,
                  style: const TextStyle(color: _textChip, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _statItem(
                'Duration',
                _formatDuration(_session.activeSeconds),
                color: _accent,
              ),
              _statItem('Ends', dtFmt.format(_session.endTime!)),
              _statItem('Players', '${_session.allPlayers.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoPaysSection() {
    String selectedPayer = 'All';
    if (_selectedPayers.length == 1) {
      selectedPayer = _selectedPayers.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Who's paying",
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        _payerRow(
          label: 'All',
          icon: Icons.groups_outlined,
          value: 'All',
          currentSelection: selectedPayer,
        ),
        const SizedBox(height: 8),
        for (final player in _session.allPlayers) ...[
          _payerRow(
            label: player,
            icon: Icons.person_outline,
            value: player,
            currentSelection: selectedPayer,
          ),
          const SizedBox(height: 8),
        ],
        Center(
          child: TextButton.icon(
            onPressed: () => _showAddPlayerDialog(),
            icon: const Icon(Icons.person_add_alt_1, size: 16, color: _accent),
            label: const Text(
              'Add player to bill',
              style: TextStyle(color: _accent, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _payerRow({
    required String label,
    required IconData icon,
    required String value,
    required String currentSelection,
  }) {
    final bool selected = currentSelection == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPayers.clear();
          if (value != 'All') {
            _selectedPayers.add(value);
            if (_paymentMethod == PaymentMethod.credit) {
              _PlayerProfileName = value;
            }
          } else {
            _PlayerProfileName = null;
          }

          _playerPaymentSplits.clear();
          for (final p in _session.allPlayers) {
            _playerPaymentSplits[p] = {PaymentMethod.cash: 0.0};
          }
          _initializeLiabilities();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _accentTint : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _accent : _border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _accent.withOpacity(0.18) : _chipBg,
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? _accent : _textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _textPrimary : _textChip,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _accent : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: _radioBorder, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: _bg)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders & Food',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final order in _session.orders) ...[
            _summaryRow(
              order.productName,
              '₹${order.total.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
          ],
          Divider(color: _border, height: 16),
          _summaryRow('Orders Total', '₹${_ordersTotal.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard() {
    final roundingAdjustment = _roundedTotal - _finalTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _summaryRow('Base charge', '₹${_baseGameCharge.toStringAsFixed(2)}'),
          if (_overtimeCharge > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Overtime', '₹${_overtimeCharge.toStringAsFixed(2)}'),
          ],
          if (_ordersTotal > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Orders', '₹${_ordersTotal.toStringAsFixed(2)}'),
          ],
          const SizedBox(height: 12),
          Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Apply discount',
                style: TextStyle(color: _textChip, fontSize: 13),
              ),
              Switch(
                value: _hasDiscount,
                onChanged: (v) {
                  setState(() {
                    _hasDiscount = v;
                    if (!v) {
                      _discountAmount = 0.0;
                      _discountController.text = '';
                    } else {
                      _discountAmount = _gameCharge * 0.1; // Default 10%
                      _discountController.text = _discountAmount
                          .toStringAsFixed(0);
                    }
                    _initializeLiabilities();
                  });
                },
                activeColor: _accent,
              ),
            ],
          ),
          if (_hasDiscount) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Discount Amount (₹)',
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
                SizedBox(
                  width: 80,
                  height: 32,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: _chipBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _discountAmount = double.tryParse(val) ?? 0.0;
                        _initializeLiabilities();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _summaryRow(
            'Rounding adjustment',
            '${roundingAdjustment < 0 ? '-' : '+'} ₹${roundingAdjustment.abs().toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Final amount',
                style: TextStyle(color: _textChip, fontSize: 14),
              ),
              Text(
                '₹${_roundedTotal.round()}',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    final player = _selectedPayers.isNotEmpty
        ? _selectedPayers.first
        : (_session.allPlayers.isEmpty ? 'Guest' : _session.allPlayers.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment method',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => PlayerSplitPaymentSheet(
                    playerName: player,
                    totalLiability: _finalTotal,
                    initialSplits:
                        _playerPaymentSplits[player] ??
                        {_paymentMethod: _finalTotal},
                    onSplitsSaved: (newSplits) {
                      setState(() {
                        _playerPaymentSplits[player] = newSplits;
                      });
                    },
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_split, size: 14, color: _accent),
                  SizedBox(width: 4),
                  Text('Split', style: TextStyle(color: _accent, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _paymentMethodButton(
                PaymentMethod.cash,
                Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _paymentMethodButton(PaymentMethod.upi, Icons.qr_code),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _paymentMethodButton(
                PaymentMethod.credit,
                Icons.credit_card,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paymentMethodButton(PaymentMethod method, IconData icon) {
    final bool selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = method;
          final player = _selectedPayers.isNotEmpty
              ? _selectedPayers.first
              : (_session.allPlayers.isEmpty
                    ? 'Guest'
                    : _session.allPlayers.first);
          _playerPaymentSplits[player] = {method: _finalTotal};
        });

        if (method == PaymentMethod.credit &&
            (_selectedPayers.isEmpty ||
                _selectedPayers.first.toLowerCase().startsWith('default'))) {
          _showCreditNameDialog(
            _selectedPayers.isNotEmpty ? _selectedPayers.first : '',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? _bg : _textChip),
            const SizedBox(height: 4),
            Text(
              method.displayName,
              style: TextStyle(
                fontSize: 12,
                color: selected ? _bg : _textChip,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _confirmPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _bg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: _bg, strokeWidth: 2),
              )
            : Text(
                'Confirm payment · ₹${_roundedTotal.round()}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
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

  void _showCreditNameDialog(String defaultName) {
    final nameCtrl = TextEditingController(
      text: defaultName.toLowerCase().startsWith('default') ? '' : defaultName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer Name for Credit'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'Enter real name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() => _PlayerProfileName = nameCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment() async {
    if (_isProcessing) return;

    final singlePayer = _selectedPayers.isNotEmpty
        ? _selectedPayers.first
        : _session.allPlayers.first;
    final isSplit = (_playerPaymentSplits[singlePayer]?.keys.length ?? 0) > 1;

    if (!_isMultiPayer &&
        !isSplit &&
        _session.gameType == GameType.standard &&
        _paymentMethod == PaymentMethod.credit &&
        (_PlayerProfileName == null ||
            _PlayerProfileName!.toLowerCase().startsWith('default'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer taking the credit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    if (!_isMultiPayer) {
      if (!isSplit) {
        final creditPayer =
            (_paymentMethod == PaymentMethod.credit &&
                _PlayerProfileName != null)
            ? _PlayerProfileName!
            : singlePayer;

        _playerPaymentSplits.clear();
        _playerPaymentSplits[creditPayer] = {_paymentMethod: _finalTotal};

        _customLiabilities.clear();
        _customLiabilities[creditPayer] = _finalTotal;
      }
    }

    final finalEndTime = _session.isManualEntry
        ? _session.endTime!
        : DateTime.now();
    final finalDate = DateFormat('yyyy-MM-dd').format(finalEndTime);

    final finalSession = _session.copyWith(
      endTime: finalEndTime,
      status: TableStatus.available,
      playerPaymentSplits: _playerPaymentSplits,
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
      paidBy:
          (_paymentMethod == PaymentMethod.credit && !_isMultiPayer && !isSplit)
          ? _PlayerProfileName
          : null,
      paymentMethod: (!isSplit) ? _paymentMethod : null,
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
