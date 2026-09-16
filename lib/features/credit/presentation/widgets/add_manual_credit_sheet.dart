import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';

class AddManualCreditSheet extends ConsumerStatefulWidget {
  final String? preSelectedPlayerName;

  const AddManualCreditSheet({
    super.key,
    this.preSelectedPlayerName,
  });

  @override
  ConsumerState<AddManualCreditSheet> createState() => _AddManualCreditSheetState();
}

class _AddManualCreditSheetState extends ConsumerState<AddManualCreditSheet> {
  late String _playerName;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _playerName = widget.preSelectedPlayerName ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_playerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a player name.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(creditRepositoryProvider);
      final refId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
      await repo.addCreditRecord(
        customerName: _playerName.trim(),
        amount: amount,
        type: CreditTransactionType.manual,
        referenceId: refId,
        title: 'Manual Khata Entry',
        subtitle: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual Khata entry added successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding entry: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPreSelected = widget.preSelectedPlayerName != null && widget.preSelectedPlayerName!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Manual Khata',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(24),
          if (isPreSelected)
            TextFormField(
              initialValue: widget.preSelectedPlayerName,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            )
          else
            PlayerSearchField(
              hint: 'Select or Enter Player Name',
              onSelected: (player) {
                setState(() {
                  _playerName = player.name;
                });
              },
            ),
          const Gap(16),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Credit Amount (\u20B9)',
              prefixIcon: const Icon(Icons.currency_rupee, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Gap(16),
          TextFormField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Note / Reason (Optional)',
              prefixIcon: const Icon(Icons.notes, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Gap(32),
          FilledButton(
            onPressed: _isProcessing ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.creditStatus,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Add Entry', style: TextStyle(fontSize: 16)),
          ),
          const Gap(24),
        ],
      ),
    );
  }
}
