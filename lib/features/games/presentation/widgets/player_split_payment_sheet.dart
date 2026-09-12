import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/core/theme/app_colors.dart';

class PlayerSplitPaymentSheet extends StatefulWidget {
  final String playerName;
  final double totalLiability;
  final Map<PaymentMethod, double> initialSplits;
  final void Function(Map<PaymentMethod, double>) onSplitsSaved;

  const PlayerSplitPaymentSheet({
    Key? key,
    required this.playerName,
    required this.totalLiability,
    required this.initialSplits,
    required this.onSplitsSaved,
  }) : super(key: key);

  @override
  State<PlayerSplitPaymentSheet> createState() => _PlayerSplitPaymentSheetState();
}

class _PlayerSplitPaymentSheetState extends State<PlayerSplitPaymentSheet> {
  final Map<PaymentMethod, TextEditingController> _controllers = {};
  double _currentSum = 0.0;

  @override
  void initState() {
    super.initState();
    for (final method in PaymentMethod.values) {
      final amount = widget.initialSplits[method] ?? 0.0;
      final controller = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(2) : '');
      controller.addListener(_recalculateSum);
      _controllers[method] = controller;
    }
    _recalculateSum();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _recalculateSum() {
    double sum = 0.0;
    for (final controller in _controllers.values) {
      final value = double.tryParse(controller.text) ?? 0.0;
      sum += value;
    }
    setState(() {
      _currentSum = sum;
    });
  }

  void _save() {
    if ((_currentSum - widget.totalLiability).abs() > 0.01) {
      return; // Validation fails
    }

    final result = <PaymentMethod, double>{};
    for (final entry in _controllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0.0;
      if (amount > 0) {
        result[entry.key] = amount;
      }
    }
    widget.onSplitsSaved(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = (_currentSum - widget.totalLiability).abs() <= 0.01;
    final diff = widget.totalLiability - _currentSum;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Split Payment: ${widget.playerName}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Liability:', style: theme.textTheme.bodyMedium),
                Text(
                  '₹${widget.totalLiability.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Gap(16),
          ...PaymentMethod.values.where((m) => !(m == PaymentMethod.credit && widget.playerName.toLowerCase().startsWith('default'))).map((method) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      method.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _controllers[method],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Allocated: ₹${_currentSum.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
              Text(
                diff.abs() < 0.01
                    ? 'Perfectly Split'
                    : diff > 0
                        ? 'Remaining: ₹${diff.toStringAsFixed(2)}'
                        : 'Overpaid: ₹${diff.abs().toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: diff.abs() < 0.01 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: isValid ? _save : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Split Payment'),
          ),
        ],
      ),
    );
  }
}
