import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/happy_hour/domain/models/happy_hour_offer.dart';
import 'package:snooker_club/features/happy_hour/providers/happy_hour_providers.dart';

class OfferSelectionSheet extends ConsumerStatefulWidget {
  final String tableId;
  final String tableName;
  final HappyHourOffer? currentOffer;
  final double currentStandardCharge;

  const OfferSelectionSheet({
    super.key,
    required this.tableId,
    required this.tableName,
    this.currentOffer,
    required this.currentStandardCharge,
  });

  @override
  ConsumerState<OfferSelectionSheet> createState() => _OfferSelectionSheetState();
}

class _OfferSelectionSheetState extends ConsumerState<OfferSelectionSheet> {
  final TextEditingController _codeController = TextEditingController();
  String? _codeLookupError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _lookupCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final allOffersAsync = ref.read(happyHourOffersProvider);
    final allOffers = allOffersAsync.value ?? [];

    HappyHourOffer? match;
    for (final o in allOffers) {
      if (o.code == code) {
        match = o;
        break;
      }
    }

    if (match == null) {
      setState(() => _codeLookupError = 'No offer found with code "$code"');
      return;
    }
    final foundOffer = match;

    if (!foundOffer.isActive) {
      setState(() => _codeLookupError = 'Offer "$code" is currently inactive.');
      return;
    }

    if (!foundOffer.isTimeEligible(DateTime.now())) {
      setState(
        () => _codeLookupError =
            'Offer "$code" is not valid at this time (${foundOffer.dailyStartTime} - ${foundOffer.dailyEndTime}).',
      );
      return;
    }

    if (!foundOffer.gameOffers.containsKey(widget.tableId)) {
      setState(
        () => _codeLookupError =
            'Offer "$code" does not apply to ${widget.tableName}.',
      );
      return;
    }

    // Match found and eligible
    Navigator.pop(context, foundOffer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eligibleOffers =
        ref.watch(eligibleOffersForTableProvider(widget.tableId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.discount_outlined,
                    color: Colors.deepOrangeAccent,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Happy Hour Offer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Eligible deals for ${widget.tableName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.currentOffer != null)
                  TextButton.icon(
                    onPressed: () {
                      // Remove applied offer
                      Navigator.pop(context, false);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Search / code input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter offer code (e.g. WKND50)',
                      prefixIcon: const Icon(Icons.qr_code, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _codeLookupError,
                    ),
                    onSubmitted: (_) => _lookupCode(),
                  ),
                ),
                const Gap(8),
                FilledButton(
                  onPressed: _lookupCode,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const Gap(16),

          // List of eligible offers
          Flexible(
            child: eligibleOffers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const Gap(12),
                        Text(
                          'No active offers for this table right now.',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Happy hour offers appear automatically when the current time matches configured promotional hours.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: eligibleOffers.length,
                    separatorBuilder: (_, _) => const Gap(10),
                    itemBuilder: (context, index) {
                      final offer = eligibleOffers[index];
                      final isSelected = widget.currentOffer?.id == offer.id;
                      final promoPrice =
                          offer.gameOffers[widget.tableId] ?? 0.0;
                      final savings = widget.currentStandardCharge > promoPrice
                          ? widget.currentStandardCharge - promoPrice
                          : 0.0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        offer.name,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Gap(8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          offer.code,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(4),
                                  Text(
                                    'Valid: ${offer.dailyStartTime} - ${offer.dailyEndTime}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const Gap(6),
                                  Row(
                                    children: [
                                      Text(
                                        '₹${promoPrice.toStringAsFixed(0)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      if (savings > 0) ...[
                                        const Gap(8),
                                        Text(
                                          '(Save ₹${savings.toStringAsFixed(0)})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Gap(12),
                            if (isSelected)
                              const Chip(
                                avatar: Icon(
                                  Icons.check,
                                  color: AppColors.success,
                                  size: 16,
                                ),
                                label: Text(
                                  'Applied',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              FilledButton.tonal(
                                onPressed: () {
                                  Navigator.pop(context, offer);
                                },
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Apply'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}
