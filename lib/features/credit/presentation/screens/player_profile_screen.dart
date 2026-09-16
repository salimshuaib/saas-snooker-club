import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/screens/bill_details_screen.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sale_details_screen.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/credit/presentation/widgets/add_manual_credit_sheet.dart' as snooker_manual_credit;

final playerGamesProvider = FutureProvider.autoDispose
    .family<List<GameSession>, PlayerProfile>((ref, player) async {
      final repo = ref.watch(gamesRepositoryProvider);
      return repo.getGamesForPlayer(player.id, player.name);
    });

final playerQuickSalesProvider = StreamProvider.autoDispose
    .family<List<QuickSale>, PlayerProfile>((ref, player) {
      return ref
          .watch(quickSalesRepositoryProvider)
          .watchAllQuickSales()
          .map(
            (sales) => sales
                .where(
                  (s) =>
                      s.customerId == player.id ||
                      s.customerName == player.name,
                )
                .toList(),
          );
    });

class PlayerProfileScreen extends ConsumerStatefulWidget {
  final PlayerProfile customer;

  const PlayerProfileScreen({super.key, required this.customer});

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(allCustomersProvider);
    final currentCustomer = customersAsync.maybeWhen(
      data: (list) => list.firstWhere(
        (c) => c.id == widget.customer.id,
        orElse: () => widget.customer,
      ),
      orElse: () => widget.customer,
    );

    final gamesAsync = ref.watch(playerGamesProvider(currentCustomer));
    final quickSalesAsync = ref.watch(
      playerQuickSalesProvider(currentCustomer),
    );
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Add Manual Khata',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => snooker_manual_credit.AddManualCreditSheet(
                  preSelectedPlayerName: currentCustomer.name,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => _editCustomerName(context, currentCustomer),
          ),
        ],
      ),
      body: Column(
        children: [
          _ProfileHeaderCard(
            customer: currentCustomer,
            gamesAsync: gamesAsync,
            quickSalesAsync: quickSalesAsync,
            currency: currency,
          ),
          const Gap(16),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Transactions'),
                      Tab(text: 'Game History'),
                      Tab(text: 'Quick Sales'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _TransactionsTab(
                          customerId: currentCustomer.id,
                          currency: currency,
                        ),
                        _GamesTab(
                          gamesAsync: gamesAsync,
                          currency: currency,
                          customer: currentCustomer,
                        ),
                        _QuickSalesTab(
                          quickSalesAsync: quickSalesAsync,
                          currency: currency,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: currentCustomer.outstandingAmount > 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showPaymentBottomSheet(context, currentCustomer),
              backgroundColor: AppColors.success,
              icon: const Icon(Icons.payments, color: Colors.white),
              label: const Text(
                'Receive Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _editCustomerName(
    BuildContext context,
    PlayerProfile customer,
  ) async {
    final nameController = TextEditingController(text: customer.name);
    final mobileController = TextEditingController(
      text: customer.mobileNumber ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(16),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final newName = nameController.text.trim();
      final newMobile = mobileController.text.trim();
      if (newName.isNotEmpty) {
        try {
          final updatedProfile = customer.copyWith(
            name: newName,
            mobileNumber: newMobile.isEmpty ? null : newMobile,
          );
          await ref
              .read(creditRepositoryProvider)
              .savePlayerProfile(updatedProfile);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating profile: $e')),
            );
          }
        }
      }
    }
  }

  void _showPaymentBottomSheet(BuildContext context, PlayerProfile customer) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _PaymentSheet(customer: customer),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends ConsumerWidget {
  final PlayerProfile customer;
  final AsyncValue<List<GameSession>> gamesAsync;
  final AsyncValue<List<QuickSale>> quickSalesAsync;
  final dynamic currency;

  const _ProfileHeaderCard({
    required this.customer,
    required this.gamesAsync,
    required this.quickSalesAsync,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    int totalGames = 0;
    int snookerGames = 0;
    int poolGames = 0;

    gamesAsync.whenData((games) {
      totalGames = games.length;
      for (final g in games) {
        if (g.tableType == TableType.snooker)
          snookerGames++;
        else
          poolGames++;
      }
    });

    final transactionsAsync = ref.watch(allTransactionsProvider(customer.id));

    double totalMoneyPaid = 0;
    transactionsAsync.whenData((txs) {
      for (final tx in txs) {
        if (tx.status == CreditTransactionStatus.paid) {
          totalMoneyPaid += tx.paidAmount;
        }
      }
    });

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customer.mobileNumber != null &&
                        customer.mobileNumber!.isNotEmpty)
                      Text(
                        '📱 ${customer.mobileNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      'ID: ${customer.id.substring(0, 8).toUpperCase()}',
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
                    'Outstanding',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    CurrencyHelper.format(customer.outstandingAmount, currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: customer.outstandingAmount > 0
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Total Games', value: totalGames.toString()),
              _StatItem(label: 'Snooker', value: snookerGames.toString()),
              _StatItem(label: 'Pool', value: poolGames.toString()),
              _StatItem(
                label: 'Total Paid',
                value: CurrencyHelper.format(totalMoneyPaid, currency),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GamesTab extends StatelessWidget {
  final AsyncValue<List<GameSession>> gamesAsync;
  final dynamic currency;
  final PlayerProfile customer;
  const _GamesTab({
    required this.gamesAsync,
    required this.currency,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return gamesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (games) {
        if (games.isEmpty) {
          return const Center(child: Text('No game history found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];

            final bool didAnotherPlayerPay =
                game.paidBy != null &&
                game.paidBy!.trim().toLowerCase() !=
                    customer.name.trim().toLowerCase();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  '${game.tableName} (${game.tableType.displayName})',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMM d, y h:mm a').format(game.startTime)),
                    if (didAnotherPlayerPay) ...[
                      const Gap(2),
                      Text(
                        'Paid by: ${game.paidBy}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.format(
                        game.finalAmount ?? game.grandTotal ?? 0,
                        currency,
                      ),
                      style: TextStyle(
                        decoration: didAnotherPlayerPay
                            ? TextDecoration.lineThrough
                            : null,
                        color: didAnotherPlayerPay ? Colors.grey : null,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (didAnotherPlayerPay)
                      const Text(
                        'Not liable',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BillDetailsScreen(session: game),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickSalesTab extends StatelessWidget {
  final AsyncValue<List<QuickSale>> quickSalesAsync;
  final dynamic currency;
  const _QuickSalesTab({required this.quickSalesAsync, required this.currency});

  @override
  Widget build(BuildContext context) {
    return quickSalesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(child: Text('No quick sales found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Items: ${sale.items.length}'),
                subtitle: Text(DateFormat('MMM d, y h:mm a').format(sale.date)),
                trailing: Text(
                  CurrencyHelper.format(sale.totalAmount, currency),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuickSaleDetailsScreen(sale: sale),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  final String customerId;
  final dynamic currency;
  const _TransactionsTab({required this.customerId, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider(customerId));

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading transactions: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('No transaction history.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isCreditGiven =
                tx.status == CreditTransactionStatus.pending ||
                tx.status == CreditTransactionStatus.partiallyPaid;

            final icon = isCreditGiven
                ? Icons.arrow_upward
                : Icons.arrow_downward;
            final color = isCreditGiven ? AppColors.error : AppColors.success;

            String mainTitle = '';
            if (isCreditGiven) {
              mainTitle = 'Credit Given';
            } else {
              mainTitle = 'Payment Received';
            }

            String subTitle = tx.title;
            if (tx.paymentMethod != null) {
              subTitle += ' • ${tx.paymentMethod!.displayName}';
            }
            if (tx.subtitle != null) {
              subTitle += '\n${tx.subtitle}';
            }
            subTitle +=
                '\n${DateFormat('MMM d, yyyy - h:mm a').format(tx.date)}';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                isThreeLine: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  mainTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(subTitle),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.format(tx.amount, currency),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isCreditGiven)
                      const Text(
                        'Pending',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      )
                    else
                      const Text(
                        'Paid',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentSheet extends ConsumerStatefulWidget {
  final PlayerProfile customer;
  const _PaymentSheet({required this.customer});

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _amountController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submitPayment() async {
    if (_isLoading) return;
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid positive amount');
      return;
    }

    final roundedOutstanding = double.parse(
      widget.customer.outstandingAmount.toStringAsFixed(2),
    );
    final roundedAmount = double.parse(amount.toStringAsFixed(2));

    if (roundedAmount > roundedOutstanding) {
      _showError('Amount cannot exceed outstanding balance');
      return;
    }

    // Security check omitted for now
    setState(() => _isLoading = true);
    try {
      await ref
          .read(creditControllerProvider.notifier)
          .processPayment(
            customer: widget.customer,
            paymentAmount: amount,
            paymentMethod: _paymentMethod,
            employeeName: 'Admin',
            isFullPayment: amount == widget.customer.outstandingAmount,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Receive Payment',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Outstanding',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  CurrencyHelper.format(
                    widget.customer.outstandingAmount,
                    currency,
                  ),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Payment Amount',
              prefixText: ' ',
              border: OutlineInputBorder(),
            ),
          ),
          const Gap(24),
          Text('Payment Method', style: theme.textTheme.titleSmall),
          const Gap(8),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.cash,
                label: Text('Cash'),
                icon: Icon(Icons.money),
              ),
              ButtonSegment(
                value: PaymentMethod.upi,
                label: Text('UPI'),
                icon: Icon(Icons.qr_code),
              ),
            ],
            selected: {_paymentMethod},
            onSelectionChanged: (set) =>
                setState(() => _paymentMethod = set.first),
          ),
          const Gap(32),
          FilledButton(
            onPressed: _isLoading ? null : _submitPayment,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.success,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirm Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
