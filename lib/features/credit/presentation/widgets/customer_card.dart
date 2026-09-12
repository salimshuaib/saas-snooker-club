import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/models/currency.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';

class CustomerCard extends StatefulWidget {
  final PlayerProfile customer;
  final Currency currency;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onToggle;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.currency,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggle,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  Timer? _timer;
  bool _longPressTriggered = false;

  void _startTimer() {
    if (widget.isSelectionMode) return;

    _timer = Timer(const Duration(seconds: 3), () {
      HapticFeedback.heavyImpact();
      _longPressTriggered = true;
      widget.onToggle();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;
    final isSelectionMode = widget.isSelectionMode;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTapDown: (_) => _startTimer(),
        onTapCancel: () => _cancelTimer(),
        onTap: () {
          _cancelTimer();
          if (_longPressTriggered) {
            _longPressTriggered = false;
            return;
          }
          if (isSelectionMode) {
            widget.onToggle();
          } else {
            context.push('/more/credit/details', extra: widget.customer);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  widget.customer.name.isNotEmpty
                      ? widget.customer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Last updated: ${widget.customer.lastTransactionDate.year == 2000 ? 'Never' : '${widget.customer.lastTransactionDate.day}/${widget.customer.lastTransactionDate.month}/${widget.customer.lastTransactionDate.year}'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatWhole(
                      widget.customer.outstandingAmount,
                      widget.currency,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: widget.customer.outstandingAmount > 0
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.customer.outstandingAmount > 0
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.customer.outstandingAmount > 0
                          ? 'Outstanding'
                          : 'Cleared',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.customer.outstandingAmount > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
