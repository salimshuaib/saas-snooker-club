import 'package:flutter/material.dart';
import 'package:snooker_club/core/widgets/shared/date_navigation_header.dart';
import 'package:snooker_club/features/games/presentation/screens/bill_details_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:collection/collection.dart';

class PendingBillsScreen extends ConsumerStatefulWidget {
  const PendingBillsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PendingBillsScreen> createState() => _PendingBillsScreenState();
}

class _PendingBillsScreenState extends ConsumerState<PendingBillsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingBillsState = ref.watch(pendingBillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Bills'),
        centerTitle: true,
      ),
      body: pendingBillsState.when(
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  const Gap(16),
                  Text(
                    'No Pending Bills',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final targetDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
          final dateFilteredBills = bills.where((b) {
            if (b.markedPendingAt != null) {
              return DateFormat('yyyy-MM-dd').format(b.markedPendingAt!) == targetDateStr;
            }
            return b.date == targetDateStr;
          }).toList();

          final filteredBills = _searchQuery.isEmpty
              ? dateFilteredBills
              : dateFilteredBills.where((b) {
                  final name = b.pendingBillCustomerName?.toLowerCase() ?? '';
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

          // Group by customer
          final grouped = groupBy(filteredBills, (GameSession g) => g.pendingBillCustomerId ?? 'unknown');
          
          return Column(
            children: [
              DateNavigationHeader(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: grouped.isEmpty 
                  ? Center(
                      child: Text(
                        'No pending bills for this date.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final customerId = grouped.keys.elementAt(index);
                    final customerBills = grouped[customerId]!;
                    final customerName = customerBills.first.pendingBillCustomerName ?? 'Unknown';
                    final totalAmount = customerBills.fold(0.0, (sum, g) => sum + (g.finalAmount ?? g.grandTotal ?? 0.0));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          child: const Icon(Icons.person, color: Colors.orange),
                        ),
                        title: Text(
                          customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${customerBills.length} pending bill(s)'),
                        trailing: Text(
                          '₹${totalAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        children: [
                          ...customerBills.map((bill) => _buildBillTile(context, bill)),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                    // Handle combined settlement (Phase 5)
                                    // For now just show snackbar
                                    context.push(
                                      RouteNames.combinedSettlement,
                                      extra: {
                                        'customerId': customerId,
                                        'customerName': customerName,
                                        'initialBills': customerBills,
                                      },
                                    );
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                                  child: const Text('Settle Bill(s)'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBillTile(BuildContext context, GameSession bill) {
    final theme = Theme.of(context);
    final amount = bill.finalAmount ?? bill.grandTotal ?? 0.0;
    
    // Check if overdue (> 24 hours)
    final age = DateTime.now().difference(bill.markedPendingAt ?? DateTime.now());
    final isOverdue = age.inDays >= 7;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(bill.tableName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd MMM yyyy, hh:mm a').format(bill.endTime ?? DateTime.now())),
          if (isOverdue)
            Text(
              'Overdue (${age.inDays} days)',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BillDetailsScreen(session: bill)),
          );
      },
    );
  }
}
