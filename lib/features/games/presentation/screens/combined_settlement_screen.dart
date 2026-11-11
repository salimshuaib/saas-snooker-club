import 'package:flutter/material.dart';
import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';
import 'package:snooker_club/core/utils/billing_utils.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/upi_qr_dialog.dart';
import 'package:snooker_club/features/games/presentation/widgets/payment_complete_modal.dart';

class CombinedSettlementScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final List<GameSession> initialBills;

  const CombinedSettlementScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
    required this.initialBills,
  }) : super(key: key);

  @override
  ConsumerState<CombinedSettlementScreen> createState() =>
      _CombinedSettlementScreenState();
}

class _CombinedSettlementScreenState
    extends ConsumerState<CombinedSettlementScreen> {
  final Set<String> _selectedBillIds = {};
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;
  Map<PaymentMethod, double> _playerPaymentSplits = {};

  late List<GameSession> _localBills;

  bool _hasDiscount = false;
  double _newDiscountAmount = 0.0;
  final TextEditingController _discountPercentController =
      TextEditingController();
  final TextEditingController _discountAmountController =
      TextEditingController();
  final TextEditingController _discountedGameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _localBills = List.from(widget.initialBills);
    // Default to all selected
    for (final bill in _localBills) {
      _selectedBillIds.add(bill.id);
    }
  }

  double get _totalSelectedAmount {
    final unrounded =
        _localBills
            .where((b) => _selectedBillIds.contains(b.id))
            .fold(0.0, (sum, bill) => sum + _billPayableAmount(bill)) -
        _appliedNewDiscountAmount;
    return BillingUtils.roundAmount(unrounded);
  }

  double _billGrossTotal(GameSession bill) =>
      (bill.gameCharge ?? 0.0) +
      (bill.ordersTotal ??
          bill.orders.fold<double>(0.0, (sum, order) => sum + order.total)) +
      bill.manualGameCharges.fold<double>(
        0.0,
        (sum, charge) => sum + charge.calculatedAmount,
      );

  double _billItemDiscounts(GameSession bill) =>
      (bill.currentGameDiscountAmount ?? 0.0) +
      bill.manualGameCharges.fold<double>(
        0.0,
        (sum, charge) => sum + charge.appliedDiscountAmount,
      );

  double _billPayableAmount(GameSession bill) {
    final gross = _billGrossTotal(bill);
    final itemDiscounts = _billItemDiscounts(bill);
    final billDiscount = (bill.discountAmount ?? 0.0)
        .clamp(0.0, math.max(0.0, gross - itemDiscounts))
        .toDouble();
    return math.max(0.0, gross - itemDiscounts - billDiscount).toDouble();
  }

  double get _appliedNewDiscountAmount =>
      _newDiscountAmount.clamp(0.0, _totalDiscountableAmount).toDouble();

  double get _totalDiscountableAmount {
    return _localBills
        .where((bill) => _selectedBillIds.contains(bill.id))
        .fold<double>(0.0, (sum, bill) {
          final gameAndManualAfterItemDiscounts =
              math
                  .max(
                    0.0,
                    (bill.gameCharge ?? 0.0) -
                        (bill.currentGameDiscountAmount ?? 0.0),
                  )
                  .toDouble() +
              bill.manualGameCharges.fold<double>(
                0.0,
                (manualSum, charge) => manualSum + charge.finalAmount,
              );
          final ordersTotal =
              bill.ordersTotal ??
              bill.orders.fold<double>(0.0, (sum, order) => sum + order.total);
          final preBillDiscountTotal =
              gameAndManualAfterItemDiscounts + ordersTotal;
          final appliedBillDiscount = (bill.discountAmount ?? 0.0)
              .clamp(0.0, preBillDiscountTotal)
              .toDouble();
          final billDiscountShare = preBillDiscountTotal > 0
              ? appliedBillDiscount *
                    gameAndManualAfterItemDiscounts /
                    preBillDiscountTotal
              : 0.0;
          return sum +
              math
                  .max(0.0, gameAndManualAfterItemDiscounts - billDiscountShare)
                  .toDouble();
        });
  }

  double get _totalGameCharges {
    return _localBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.gameCharge ?? 0.0));
  }

  double get _totalOrders {
    return _localBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.ordersTotal ?? 0.0));
  }

  double get _totalManualGames {
    return _localBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(
          0.0,
          (sum, b) =>
              sum +
              b.manualGameCharges.fold<double>(
                0.0,
                (s, g) => s + g.calculatedAmount,
              ),
        );
  }

  double get _totalDiscount {
    return _localBills
            .where((b) => _selectedBillIds.contains(b.id))
            .fold<double>(
              0.0,
              (sum, bill) =>
                  sum + _billGrossTotal(bill) - _billPayableAmount(bill),
            ) +
        _appliedNewDiscountAmount;
  }

  Future<double?> _showItemDiscountDialog({
    required String itemName,
    required double baseAmount,
    required double initialDiscount,
  }) async {
    final amountController = TextEditingController(
      text: initialDiscount == 0 ? '' : initialDiscount.toStringAsFixed(2),
    );
    final percentController = TextEditingController(
      text: baseAmount > 0 && initialDiscount > 0
          ? (initialDiscount / baseAmount * 100).toStringAsFixed(1)
          : '',
    );
    var discount = initialDiscount.clamp(0.0, baseAmount).toDouble();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Discount - $itemName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Charge: ₹${baseAmount.toStringAsFixed(2)}'),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: percentController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Discount %',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final percent = (double.tryParse(value) ?? 0)
                            .clamp(0.0, 100.0)
                            .toDouble();
                        setDialogState(() {
                          discount = (baseAmount * percent / 100)
                              .clamp(0.0, baseAmount)
                              .toDouble();
                          amountController.text = discount == 0
                              ? ''
                              : discount.toStringAsFixed(2);
                        });
                      },
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0;
                        setDialogState(() {
                          discount = amount.clamp(0.0, baseAmount).toDouble();
                          percentController.text =
                              baseAmount > 0 && discount > 0
                              ? (discount / baseAmount * 100).toStringAsFixed(1)
                              : '';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Text(
                'Final charge: ₹${(baseAmount - discount).toStringAsFixed(2)}',
              ),
            ],
          ),
          actions: [
            if (initialDiscount > 0)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 0.0),
                child: const Text('Remove Discount'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, discount),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    amountController.dispose();
    percentController.dispose();
    return result;
  }

  Future<void> _editCurrentGameDiscount(GameSession bill) async {
    final baseAmount = bill.gameCharge ?? 0.0;
    final discount = await _showItemDiscountDialog(
      itemName: '${bill.tableName} game',
      baseAmount: baseAmount,
      initialDiscount: (bill.currentGameDiscountAmount ?? 0.0)
          .clamp(0.0, baseAmount)
          .toDouble(),
    );
    if (discount == null || !mounted) return;

    setState(() {
      final index = _localBills.indexWhere((item) => item.id == bill.id);
      if (index != -1) {
        _localBills[index] = _localBills[index].copyWith(
          currentGameDiscountAmount: discount,
        );
      }
      _newDiscountAmount = _appliedNewDiscountAmount;
      _playerPaymentSplits = {};
    });
  }

  Future<void> _editAdditionalGameDiscount(
    GameSession bill,
    ManualGameCharge manualGame,
  ) async {
    final discount = await _showItemDiscountDialog(
      itemName: '${manualGame.tableName} - ${manualGame.gameType.displayName}',
      baseAmount: manualGame.calculatedAmount,
      initialDiscount: manualGame.appliedDiscountAmount,
    );
    if (discount == null || !mounted) return;

    setState(() {
      final index = _localBills.indexWhere((item) => item.id == bill.id);
      if (index == -1) return;
      final updatedGames = _localBills[index].manualGameCharges.map((charge) {
        if (charge.id != manualGame.id) return charge;
        return charge.copyWith(discountAmount: discount);
      }).toList();
      _localBills[index] = _localBills[index].copyWith(
        manualGameCharges: updatedGames,
      );
      _newDiscountAmount = _appliedNewDiscountAmount;
      _playerPaymentSplits = {};
    });
  }

  Future<void> _confirmSettlement() async {
    if (_selectedBillIds.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final billsToSettle = _localBills
          .where((b) => _selectedBillIds.contains(b.id))
          .toList();

      final repo = ref.read(gamesRepositoryProvider);

      final unroundedTotal =
          billsToSettle.fold(
            0.0,
            (sum, bill) => sum + _billPayableAmount(bill),
          ) -
          _appliedNewDiscountAmount;
      final roundedTotal = BillingUtils.roundAmount(unroundedTotal);

      PaymentMethod methodToUse = _paymentMethod;
      if (_playerPaymentSplits.isNotEmpty && _playerPaymentSplits.length == 1) {
        methodToUse = _playerPaymentSplits.keys.first;
      }

      final isSplit = _playerPaymentSplits.length > 1;

      await repo.settlePendingBillsCombined(
        billsToSettle,
        paymentMethod: methodToUse,
        paidBy: widget.customerName,
        customerName: widget.customerName,
        roundedTotal: roundedTotal,
        additionalDiscountAmount: _appliedNewDiscountAmount,
        playerPaymentSplits: isSplit
            ? {widget.customerName: _playerPaymentSplits}
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully settled ${billsToSettle.length} bill(s).',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to settle bills: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showAddOrderSheet() async {
    final selectedBills = _localBills
        .where((b) => _selectedBillIds.contains(b.id))
        .toList();
    if (selectedBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one bill to add items to.'),
        ),
      );
      return;
    }
    final targetBill = selectedBills.first;

    final updated = await showModalBottomSheet<AddItemsResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OrdersSheet(
        players: [widget.customerName],
        currentOrders: targetBill.orders,
        currentManualGameCharges: targetBill.manualGameCharges,
        enableGamesTab: true,
        floorId: targetBill.floorId,
        floorName: targetBill.floorName,
      ),
    );

    if (updated != null && mounted) {
      final newOrders = updated.orders;
      final newManualGames = updated.manualGameCharges;

      double ordersTotal = newOrders.fold(0, (sum, item) => sum + item.total);
      double manualGamesTotal = newManualGames.fold<double>(
        0,
        (s, g) => s + g.calculatedAmount,
      );
      double grandTotal =
          (targetBill.gameCharge ?? 0) + ordersTotal + manualGamesTotal;
      final manualGamesDiscount = newManualGames.fold<double>(
        0.0,
        (sum, charge) => sum + charge.appliedDiscountAmount,
      );
      double unroundedFinalAmount = math.max(
        0.0,
        grandTotal -
            (targetBill.discountAmount ?? 0.0) -
            (targetBill.currentGameDiscountAmount ?? 0.0) -
            manualGamesDiscount,
      );
      double finalAmount = BillingUtils.roundAmount(unroundedFinalAmount);

      try {
        await ref
            .read(gamesRepositoryProvider)
            .updatePendingBillOrders(
              targetBill,
              newOrders,
              newManualGames,
              ordersTotal,
              manualGamesTotal,
              grandTotal,
              finalAmount,
            );
        setState(() {
          final index = _localBills.indexWhere((b) => b.id == targetBill.id);
          if (index != -1) {
            _localBills[index] = targetBill.copyWith(
              orders: newOrders,
              manualGameCharges: newManualGames,
              ordersTotal: ordersTotal,
              grandTotal: grandTotal,
              roundedAmount: finalAmount,
              finalAmount: finalAmount,
            );
            _playerPaymentSplits = {};
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: '),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalSelectedAmount;
    final totalGameCharges = _totalGameCharges;
    final totalOrders = _totalOrders;
    final totalManualGames = _totalManualGames;
    final totalDiscount = _totalDiscount;
    final unroundedTotal =
        totalGameCharges + totalOrders + totalManualGames - totalDiscount;
    final totalRounding = total - unroundedTotal;
    final appSettings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Settle Bills: ${widget.customerName}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _localBills.length,
              itemBuilder: (context, index) {
                final bill = _localBills[index];
                final isSelected = _selectedBillIds.contains(bill.id);
                final amount = _billPayableAmount(bill);
                final gameCharge = bill.gameCharge ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedBillIds.add(bill.id);
                              } else {
                                _selectedBillIds.remove(bill.id);
                              }
                              _newDiscountAmount = _appliedNewDiscountAmount;
                              _playerPaymentSplits = {};
                            });
                          },
                          title: Text(bill.tableName),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM hh:mm a',
                            ).format(bill.endTime ?? DateTime.now()),
                          ),
                          secondary: Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (gameCharge > 0) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                          _editCurrentGameDiscount(bill),
                                      icon: const Icon(
                                        Icons.discount_outlined,
                                        size: 16,
                                      ),
                                      label: Text(
                                        (bill.currentGameDiscountAmount ?? 0) >
                                                0
                                            ? 'Edit discount'
                                            : 'Apply discount',
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    Text(
                                      '₹${math.max(0.0, gameCharge - (bill.currentGameDiscountAmount ?? 0.0)).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((bill.currentGameDiscountAmount ?? 0) > 0)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Discount: -₹${(bill.currentGameDiscountAmount ?? 0).clamp(0.0, gameCharge).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        ...bill.manualGameCharges.map(
                          (manualGame) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${manualGame.tableName} · ${manualGame.gameType.displayName}',
                                      ),
                                    ),
                                    Text(
                                      '₹${manualGame.finalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (manualGame.appliedDiscountAmount > 0)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Discount: -₹${manualGame.appliedDiscountAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _editAdditionalGameDiscount(
                                          bill,
                                          manualGame,
                                        ),
                                    icon: const Icon(
                                      Icons.discount_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      manualGame.appliedDiscountAmount > 0
                                          ? 'Edit discount'
                                          : 'Apply discount',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Breakdown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddOrderSheet,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  if (totalGameCharges > 0 || totalManualGames > 0) ...[
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount (Games Only)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _hasDiscount,
                          onChanged: (val) {
                            setState(() {
                              _hasDiscount = val;
                              if (!val) {
                                _newDiscountAmount = 0.0;
                                _discountPercentController.text = '';
                                _discountAmountController.text = '';
                                _discountedGameController.text =
                                    _totalDiscountableAmount.toStringAsFixed(0);
                                _playerPaymentSplits = {};
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_hasDiscount) ...[
                      const Gap(8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _discountPercentController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '%',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (val) {
                                final percent = (double.tryParse(val) ?? 0.0)
                                    .clamp(0.0, 100.0)
                                    .toDouble();
                                final amount =
                                    _totalDiscountableAmount * (percent / 100);
                                setState(() {
                                  _newDiscountAmount = amount;
                                  _playerPaymentSplits = {};
                                  _discountAmountController.text = amount == 0
                                      ? ''
                                      : amount.toStringAsFixed(0);
                                  final finalCharge =
                                      _totalDiscountableAmount - amount;
                                  _discountedGameController.text =
                                      finalCharge == 0
                                      ? ''
                                      : finalCharge.toStringAsFixed(0);
                                });
                              },
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: TextFormField(
                              controller: _discountAmountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '₹',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (val) {
                                final amount = (double.tryParse(val) ?? 0.0)
                                    .clamp(0.0, _totalDiscountableAmount)
                                    .toDouble();
                                final percent = _totalDiscountableAmount > 0
                                    ? (amount / _totalDiscountableAmount) * 100
                                    : 0.0;
                                setState(() {
                                  _newDiscountAmount = amount;
                                  _playerPaymentSplits = {};
                                  _discountPercentController.text = percent == 0
                                      ? ''
                                      : percent.toStringAsFixed(1);
                                  final finalCharge =
                                      _totalDiscountableAmount - amount;
                                  _discountedGameController.text =
                                      finalCharge == 0
                                      ? ''
                                      : finalCharge.toStringAsFixed(0);
                                });
                              },
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: TextFormField(
                              controller: _discountedGameController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Final Games',
                                prefixText: '₹',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (val) {
                                double finalGame =
                                    double.tryParse(val) ??
                                    _totalDiscountableAmount;
                                finalGame = finalGame
                                    .clamp(0.0, _totalDiscountableAmount)
                                    .toDouble();
                                final amount =
                                    _totalDiscountableAmount - finalGame;
                                final percent = _totalDiscountableAmount > 0
                                    ? (amount / _totalDiscountableAmount) * 100
                                    : 0.0;

                                setState(() {
                                  _newDiscountAmount = amount;
                                  _playerPaymentSplits = {};
                                  _discountAmountController.text = amount == 0
                                      ? ''
                                      : amount.toStringAsFixed(0);
                                  _discountPercentController.text = percent == 0
                                      ? ''
                                      : percent.toStringAsFixed(1);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ], // Close _hasDiscount
                    const Gap(16),
                    const Divider(height: 1),
                  ],
                  const Gap(12),
                  if (totalGameCharges > 0)
                    _InfoRow(
                      label: 'Total Game Charges',
                      value: '₹${totalGameCharges.toStringAsFixed(2)}',
                    ),
                  if (totalManualGames > 0)
                    _InfoRow(
                      label: 'Manual Games',
                      value: '₹${totalManualGames.toStringAsFixed(2)}',
                    ),
                  if (totalOrders > 0)
                    _InfoRow(
                      label: 'Orders Total',
                      value: '₹${totalOrders.toStringAsFixed(2)}',
                    ),
                  if (totalDiscount > 0)
                    _InfoRow(
                      label: 'Discount',
                      value: '-₹${totalDiscount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (totalRounding.abs() > 0.01)
                    _InfoRow(
                      label: 'Rounding',
                      value:
                          '${totalRounding > 0 ? '+' : '-'}₹${totalRounding.abs().toStringAsFixed(2)}',
                    ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total to Pay', style: theme.textTheme.titleMedium),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Gap(8),
                          TextButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) => PlayerSplitPaymentSheet(
                                  playerName: widget.customerName,
                                  totalLiability: total,
                                  initialSplits: _playerPaymentSplits.isNotEmpty
                                      ? _playerPaymentSplits
                                      : {_paymentMethod: total},
                                  onSplitsSaved: (newSplits) {
                                    setState(() {
                                      _playerPaymentSplits = newSplits;
                                    });
                                  },
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.call_split, size: 16),
                            label: const Text(
                              'Payment Breakdown',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(24),
                  Builder(
                    builder: (context) {
                      final isSplit = _playerPaymentSplits.keys.length > 1;
                      if (isSplit) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _playerPaymentSplits.entries
                                .map(
                                  (e) =>
                                      '${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 2)} ${e.key.displayName}',
                                )
                                .join(' + '),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return SegmentedButton<PaymentMethod>(
                        segments: const [
                          ButtonSegment(
                            value: PaymentMethod.cash,
                            label: Text('Cash'),
                            icon: Icon(Icons.money),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.upi,
                            label: Text('UPI / QR'),
                            icon: Icon(Icons.qr_code),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.credit,
                            label: Text('Credit / Khata'),
                            icon: Icon(Icons.account_balance_wallet),
                          ),
                        ],
                        selected: _playerPaymentSplits.isNotEmpty
                            ? {_playerPaymentSplits.keys.first}
                            : {_paymentMethod},
                        onSelectionChanged: (Set<PaymentMethod> newSelection) {
                          setState(() {
                            _paymentMethod = newSelection.first;
                            _playerPaymentSplits = {newSelection.first: total};
                          });
                        },
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.standard,
                        ),
                      );
                    },
                  ),

                  const Gap(24),
                  if ((_playerPaymentSplits.containsKey(PaymentMethod.upi) ||
                          _paymentMethod == PaymentMethod.upi) &&
                      appSettings != null &&
                      appSettings.business.upiId != null &&
                      appSettings.business.upiId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => UpiQrDialog(
                                upiId: appSettings.business.upiId!,
                                payeeName: appSettings.business.clubName,
                                amount:
                                    _playerPaymentSplits.containsKey(
                                      PaymentMethod.upi,
                                    )
                                    ? _playerPaymentSplits[PaymentMethod.upi]!
                                    : total,
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('Generate QR'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_selectedBillIds.isEmpty || _isProcessing)
                          ? null
                          : _confirmSettlement,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Confirm & Settle',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _InfoRow({required this.label, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: style ?? const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
