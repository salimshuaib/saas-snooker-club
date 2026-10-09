import os
import re

filepath = 'lib/features/games/presentation/screens/bill_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add Cancel Pending Bill logic
cancel_logic = '''
  Future<void> _cancelPendingBill(BuildContext context, GameSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Pending Bill?'),
        content: const Text('This will cancel the bill completely and restore any inventory items.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(gamesRepositoryProvider).cancelPendingBill(session.id, session);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pending bill cancelled.'), backgroundColor: AppColors.success),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
'''

content = content.replace('Future<void> _showFullEditModal(', cancel_logic + '\n  Future<void> _showFullEditModal(')

# In the body, if pendingBill, show a pending header with buttons
pending_header = '''
                  if (session.status == TableStatus.pendingBill.name) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.orange, size: 32),
                          const Gap(8),
                          Text(
                            'PENDING BILL: ${session.pendingBillCustomerName ?? ''}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Gap(16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _cancelPendingBill(context, session),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                  child: const Text('Cancel Bill'),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    import_stmt; // placeholder just to make sure we have route names
                                    context.push(
                                      '${RouteNames.history}/${RouteNames.pendingBills}/${RouteNames.combinedSettlement}',
                                      extra: {
                                        'customerId': session.pendingBillCustomerId ?? 'unknown',
                                        'customerName': session.pendingBillCustomerName ?? 'Unknown',
                                        'initialBills': [session],
                                      },
                                    );
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                                  child: const Text('Settle Bill'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Gap(24),
                  ],
'''

start_body = 'children: [\n                  if (session.isCancelled) ...['
content = content.replace(start_body, 'children: [\n' + pending_header + '                  if (session.isCancelled) ...[')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('Phase 6 complete')
