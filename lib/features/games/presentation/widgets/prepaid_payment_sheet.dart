import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/upi_qr_dialog.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';

class PrepaidPaymentResult {
  final PaymentMethod? paymentMethod;
  final Map<String, Map<PaymentMethod, double>>? playerPaymentSplits;
  final String? paidBy;
  final String? customerId;
  final double amount;

  const PrepaidPaymentResult({
    this.paymentMethod,
    this.playerPaymentSplits,
    this.paidBy,
    this.customerId,
    required this.amount,
  });
}

class PrepaidPaymentSheet extends ConsumerStatefulWidget {
  final double amount;
  final String tableName;
  final List<String> players;
  final Map<String, String>? playerIdentities;
  final String packageDescription;

  const PrepaidPaymentSheet({
    super.key,
    required this.amount,
    required this.tableName,
    required this.players,
    this.playerIdentities,
    required this.packageDescription,
  });

  static Future<PrepaidPaymentResult?> show(
    BuildContext context, {
    required double amount,
    required String tableName,
    required List<String> players,
    Map<String, String>? playerIdentities,
    required String packageDescription,
  }) {
    return showModalBottomSheet<PrepaidPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrepaidPaymentSheet(
        amount: amount,
        tableName: tableName,
        players: players,
        playerIdentities: playerIdentities,
        packageDescription: packageDescription,
      ),
    );
  }

  @override
  ConsumerState<PrepaidPaymentSheet> createState() =>
      _PrepaidPaymentSheetState();
}

class _PrepaidPaymentSheetState extends ConsumerState<PrepaidPaymentSheet> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isSplit = false;
  Map<String, Map<PaymentMethod, double>> _playerSplits = {};
  String? _creditCustomerName;
  String? _creditCustomerId;

  @override
  void initState() {
    super.initState();
    final firstPlayer = widget.players.isNotEmpty ? widget.players.first : 'Player';
    if (!firstPlayer.toLowerCase().startsWith('default')) {
      _creditCustomerName = firstPlayer;
      _creditCustomerId = widget.playerIdentities?[firstPlayer];
    }
    _initSplits();
  }

  void _initSplits() {
    if (widget.players.isEmpty) return;
    final perPlayer = widget.amount / widget.players.length;
    _playerSplits = {
      for (final p in widget.players)
        p: {PaymentMethod.cash: perPlayer},
    };
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

  void _onConfirm() {
    if (!_isSplit && _selectedMethod == PaymentMethod.credit) {
      if (_creditCustomerName == null || _creditCustomerName!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or enter the customer taking the credit.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_isSplit) {
      // Validate split total
      double totalSplit = 0.0;
      for (final playerEntry in _playerSplits.values) {
        for (final val in playerEntry.values) {
          totalSplit += val;
        }
      }
      if ((totalSplit - widget.amount).abs() > 0.5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Split amounts (₹${totalSplit.toStringAsFixed(2)}) do not match required amount (₹${widget.amount.toStringAsFixed(2)}).',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      Navigator.of(context).pop(
        PrepaidPaymentResult(
          paymentMethod: null,
          playerPaymentSplits: _playerSplits,
          amount: widget.amount,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      PrepaidPaymentResult(
        paymentMethod: _selectedMethod,
        paidBy: _selectedMethod == PaymentMethod.credit ? _creditCustomerName : null,
        customerId: _selectedMethod == PaymentMethod.credit ? _creditCustomerId : null,
        playerPaymentSplits: {
          widget.players.firstOrNull ?? 'Player': {_selectedMethod: widget.amount},
        },
        amount: widget.amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appSettings = ref.watch(appSettingsProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prepaid Payment',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      '${widget.tableName} • ${widget.packageDescription}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const Gap(16),

            // Amount Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prepaid Amount Due',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '₹${widget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // Mode Selector: Single vs Split
            if (widget.players.length > 1) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Single Payment'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Split by Player'),
                    icon: Icon(Icons.call_split),
                  ),
                ],
                selected: {_isSplit},
                onSelectionChanged: (set) {
                  setState(() => _isSplit = set.first);
                },
              ),
              const Gap(16),
            ],

            if (!_isSplit) ...[
              // Payment Method Grid
              Text(
                'Select Payment Method',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _selectedMethod == method;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedMethod = method),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceBright,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _paymentIcon(method),
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 22,
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
                    ),
                  );
                }).toList(),
              ),

              // UPI QR Helper
              if (_selectedMethod == PaymentMethod.upi &&
                  appSettings.business.upiId != null &&
                  appSettings.business.upiId!.isNotEmpty) ...[
                const Gap(12),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => UpiQrDialog(
                        upiId: appSettings.business.upiId!,
                        payeeName: appSettings.business.clubName,
                        amount: widget.amount,
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Show UPI QR Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              // Credit Customer Selection
              if (_selectedMethod == PaymentMethod.credit) ...[
                const Gap(16),
                Text(
                  'Khata Customer Profile',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(8),
                PlayerSearchField(
                  hint: 'Search or add customer for credit...',
                  initialSelection: _creditCustomerName != null
                      ? PlayerSelection(
                          id: _creditCustomerId,
                          name: _creditCustomerName!,
                        )
                      : null,
                  onSelected: (selection) {
                    setState(() {
                      _creditCustomerName = selection.name;
                      _creditCustomerId = selection.id;
                    });
                  },
                ),
              ],
            ] else ...[
              // Split breakdown
              Text(
                'Player Payment Allocations',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              ...widget.players.map((player) {
                final splits = _playerSplits[player] ?? {};
                final totalForPlayer = splits.values.fold(0.0, (s, v) => s + v);
                final methodsStr = splits.entries
                    .where((e) => e.value > 0)
                    .map((e) => '${e.key.displayName}: ₹${e.value.toStringAsFixed(2)}')
                    .join(', ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    title: Text(
                      player,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      methodsStr.isNotEmpty
                          ? methodsStr
                          : '₹${totalForPlayer.toStringAsFixed(2)}',
                    ),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.call_split, size: 16),
                      label: const Text('Edit Split'),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => PlayerSplitPaymentSheet(
                            playerName: player,
                            totalLiability: totalForPlayer > 0
                                ? totalForPlayer
                                : (widget.amount / widget.players.length),
                            initialSplits: splits,
                            onSplitsSaved: (newSplits) {
                              setState(() {
                                _playerSplits[player] = newSplits;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ],

            const Gap(24),

            // Confirm Button
            FilledButton.icon(
              onPressed: _onConfirm,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'Confirm & Start Game (₹${widget.amount.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
