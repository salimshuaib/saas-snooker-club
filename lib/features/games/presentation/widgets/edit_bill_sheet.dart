import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

/// A full-screen bottom sheet for editing a completed bill.
/// Supports: changing payer count, re-splitting amounts,
/// multi-method per player (Cash/UPI/Credit), and bill total adjustment.
class EditBillSheet extends ConsumerStatefulWidget {
  final GameSession session;

  const EditBillSheet({super.key, required this.session});

  @override
  ConsumerState<EditBillSheet> createState() => _EditBillSheetState();
}

class _EditBillSheetState extends ConsumerState<EditBillSheet> {
  late double _billTotal;
  late TextEditingController _billTotalController;
  bool _editingTotal = false;

  // Each payer: { name, cashController, upiController, creditController }
  final List<_PayerEntry> _payers = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _billTotal = widget.session.finalAmount ??
        widget.session.grandTotal ??
        0.0;
    _billTotalController = TextEditingController(
      text: _billTotal.toStringAsFixed(0),
    );

    _initializePayersFromSession();
  }

  void _initializePayersFromSession() {
    final session = widget.session;

    if (session.playerPaymentSplits != null &&
        session.playerPaymentSplits!.isNotEmpty) {
      // Multi-payer split exists
      for (final entry in session.playerPaymentSplits!.entries) {
        final playerName = entry.key;
        final splits = entry.value;

        final cashAmt = splits[PaymentMethod.cash] ?? 0.0;
        final upiAmt = splits[PaymentMethod.upi] ?? 0.0;
        final creditAmt = splits[PaymentMethod.credit] ?? 0.0;

        _payers.add(_PayerEntry(
          nameController: TextEditingController(text: playerName),
          cashController: TextEditingController(
            text: cashAmt > 0 ? cashAmt.toStringAsFixed(0) : '',
          ),
          upiController: TextEditingController(
            text: upiAmt > 0 ? upiAmt.toStringAsFixed(0) : '',
          ),
          creditController: TextEditingController(
            text: creditAmt > 0 ? creditAmt.toStringAsFixed(0) : '',
          ),
        ));
      }
    } else {
      // Single payer
      final method = session.paymentMethod ?? PaymentMethod.cash;
      final amount = _billTotal;
      final payerName = session.paidBy ??
          (session.players.isNotEmpty ? session.players.first : 'Player 1');

      _payers.add(_PayerEntry(
        nameController: TextEditingController(text: payerName),
        cashController: TextEditingController(
          text: method == PaymentMethod.cash ? amount.toStringAsFixed(0) : '',
        ),
        upiController: TextEditingController(
          text: method == PaymentMethod.upi ? amount.toStringAsFixed(0) : '',
        ),
        creditController: TextEditingController(
          text: method == PaymentMethod.credit ? amount.toStringAsFixed(0) : '',
        ),
      ));
    }

    // Add listeners
    for (final payer in _payers) {
      payer.cashController.addListener(_onAmountChanged);
      payer.upiController.addListener(_onAmountChanged);
      payer.creditController.addListener(_onAmountChanged);
    }
  }

  void _onAmountChanged() {
    setState(() {}); // Trigger rebuild for balance indicator
  }

  double get _totalAllocated {
    double total = 0;
    for (final payer in _payers) {
      total += double.tryParse(payer.cashController.text) ?? 0;
      total += double.tryParse(payer.upiController.text) ?? 0;
      total += double.tryParse(payer.creditController.text) ?? 0;
    }
    return total;
  }

  double get _balance => _billTotal - _totalAllocated;
  bool get _isBalanced => _balance.abs() < 0.50;

  double _payerTotal(_PayerEntry payer) {
    return (double.tryParse(payer.cashController.text) ?? 0) +
        (double.tryParse(payer.upiController.text) ?? 0) +
        (double.tryParse(payer.creditController.text) ?? 0);
  }

  void _addPayer() {
    final newPayer = _PayerEntry(
      nameController: TextEditingController(text: 'Player ${_payers.length + 1}'),
      cashController: TextEditingController(),
      upiController: TextEditingController(),
      creditController: TextEditingController(),
    );
    newPayer.cashController.addListener(_onAmountChanged);
    newPayer.upiController.addListener(_onAmountChanged);
    newPayer.creditController.addListener(_onAmountChanged);
    setState(() => _payers.add(newPayer));
  }

  void _removePayer(int index) {
    if (_payers.length <= 1) return;
    final payer = _payers[index];
    payer.cashController.removeListener(_onAmountChanged);
    payer.upiController.removeListener(_onAmountChanged);
    payer.creditController.removeListener(_onAmountChanged);
    payer.dispose();
    setState(() => _payers.removeAt(index));
  }

  void _splitEqually() {
    if (_payers.isEmpty) return;
    final perPayer = (_billTotal / _payers.length);
    final rounded = perPayer.floor().toDouble();
    final remainder = _billTotal - (rounded * _payers.length);

    for (int i = 0; i < _payers.length; i++) {
      final amount = i == _payers.length - 1
          ? rounded + remainder
          : rounded;
      _payers[i].cashController.text = amount.toStringAsFixed(0);
      _payers[i].upiController.text = '';
      _payers[i].creditController.text = '';
    }
    setState(() {});
  }

  void _updateBillTotal() {
    final newTotal = double.tryParse(_billTotalController.text);
    if (newTotal != null && newTotal > 0) {
      setState(() {
        _billTotal = newTotal;
        _editingTotal = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_isBalanced) return;

    setState(() => _isSaving = true);

    try {
      // Build the new payment structure
      final Map<String, Map<PaymentMethod, double>> newSplits = {};
      final List<String> newSelectedPayers = [];
      final Map<String, double> newLiabilities = {};

      for (final payer in _payers) {
        final name = payer.nameController.text.trim();
        if (name.isEmpty) continue;

        final cash = double.tryParse(payer.cashController.text) ?? 0;
        final upi = double.tryParse(payer.upiController.text) ?? 0;
        final credit = double.tryParse(payer.creditController.text) ?? 0;
        final total = cash + upi + credit;

        if (total <= 0) continue; // Skip zero-amount payers

        final methods = <PaymentMethod, double>{};
        if (cash > 0) methods[PaymentMethod.cash] = cash;
        if (upi > 0) methods[PaymentMethod.upi] = upi;
        if (credit > 0) methods[PaymentMethod.credit] = credit;

        newSplits[name] = methods;
        newSelectedPayers.add(name);
        newLiabilities[name] = total;
      }

      if (newSplits.isEmpty) {
        _showError('At least one payer with an amount is required.');
        setState(() => _isSaving = false);
        return;
      }

      // Determine overall payment method (for single payer, no split case)
      PaymentMethod? overallMethod;
      String? paidBy;

      if (newSplits.length == 1) {
        final entry = newSplits.entries.first;
        paidBy = entry.key;
        if (entry.value.length == 1) {
          overallMethod = entry.value.keys.first;
        }
      }

      await ref.read(gamesRepositoryProvider).editCompletedBill(
        session: widget.session,
        newBillTotal: _billTotal,
        newPlayerPaymentSplits: newSplits,
        newSelectedPayers: newSelectedPayers,
        newPlayerLiabilities: newLiabilities,
        newPaymentMethod: overallMethod,
        newPaidBy: paidBy,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill updated successfully. Credit accounts synced.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _billTotalController.dispose();
    for (final payer in _payers) {
      payer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bill'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _splitEqually,
            icon: const Icon(Icons.balance, size: 18),
            label: const Text('Split Equally'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Bill Total ──
                  _buildBillTotalSection(theme),
                  const Gap(16),

                  // ── Payer Controls ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payers (${_payers.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _addPayer,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add Payer'),
                      ),
                    ],
                  ),
                  const Gap(12),

                  // ── Payer Cards ──
                  for (int i = 0; i < _payers.length; i++) ...[
                    _buildPayerCard(i, theme),
                    if (i < _payers.length - 1) const Gap(12),
                  ],

                  const Gap(80), // space for bottom bar
                ],
              ),
            ),
          ),

          // ── Bottom Bar with Balance & Save ──
          _buildBottomBar(theme),
        ],
      ),
    );
  }

  Widget _buildBillTotalSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Bill Total', style: theme.textTheme.titleMedium),
          if (_editingTotal)
            SizedBox(
              width: 120,
              child: TextField(
                controller: _billTotalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₹',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: _updateBillTotal,
                  ),
                ),
                onSubmitted: (_) => _updateBillTotal(),
              ),
            )
          else
            Row(
              children: [
                Text(
                  '₹${_billTotal.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Gap(8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => setState(() => _editingTotal = true),
                  tooltip: 'Change bill total',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPayerCard(int index, ThemeData theme) {
    final payer = _payers[index];
    final payerTotal = _payerTotal(payer);
    final isDefault = payer.nameController.text.toLowerCase().startsWith('default');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Name + Remove ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: payer.nameController,
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                  ),
                ),
              ),
              if (_payers.length > 1) ...[
                const Gap(8),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: AppColors.error, size: 22),
                  onPressed: () => _removePayer(index),
                  tooltip: 'Remove payer',
                ),
              ],
            ],
          ),
          const Gap(12),

          // ── Payment Method Fields ──
          _buildAmountField(
            controller: payer.cashController,
            label: 'Cash',
            icon: Icons.payments,
            color: AppColors.success,
          ),
          const Gap(8),
          _buildAmountField(
            controller: payer.upiController,
            label: 'UPI',
            icon: Icons.qr_code_scanner,
            color: AppColors.primary,
          ),
          if (!isDefault) ...[
            const Gap(8),
            _buildAmountField(
              controller: payer.creditController,
              label: 'Credit',
              icon: Icons.credit_score,
              color: AppColors.error,
            ),
          ],
          const Gap(8),

          // ── Player Total ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Player Total', style: theme.textTheme.bodySmall),
                Text(
                  '₹${payerTotal.toStringAsFixed(0)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const Gap(8),
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        const Gap(8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final balance = _balance;
    final isBalanced = _isBalanced;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Balance indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isBalanced
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isBalanced
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isBalanced ? Icons.check_circle : Icons.error_outline,
                        size: 18,
                        color: isBalanced ? AppColors.success : AppColors.error,
                      ),
                      const Gap(8),
                      Text(
                        isBalanced ? 'Balanced' : 'Unbalanced',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isBalanced ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isBalanced
                        ? '₹${_totalAllocated.toStringAsFixed(0)} / ₹${_billTotal.toStringAsFixed(0)}'
                        : balance > 0
                            ? '₹${balance.toStringAsFixed(0)} remaining'
                            : '₹${balance.abs().toStringAsFixed(0)} over',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isBalanced ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (isBalanced && !_isSaving) ? _saveChanges : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayerEntry {
  final TextEditingController nameController;
  final TextEditingController cashController;
  final TextEditingController upiController;
  final TextEditingController creditController;

  _PayerEntry({
    required this.nameController,
    required this.cashController,
    required this.upiController,
    required this.creditController,
  });

  void dispose() {
    nameController.dispose();
    cashController.dispose();
    upiController.dispose();
    creditController.dispose();
  }
}
