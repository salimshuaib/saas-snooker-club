import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import_str = "import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';"
if import_str not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_str)

old_text = "const Text('Payment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),"
new_text = '''Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: _showAddOrderSheet,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),'''

content = content.replace(old_text, new_text)

new_method = '''
  Future<void> _showAddOrderSheet() async {
    final selectedBills = widget.initialBills.where((b) => _selectedBillIds.contains(b.id)).toList();
    if (selectedBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one bill to add items to.')),
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
        currentManualGameCharges: const [],
        enableGamesTab: false,
      ),
    );

    if (updated != null && mounted) {
      final oldOrders = targetBill.orders;
      final newOrders = updated.orders;
      
      double ordersTotal = newOrders.fold(0, (sum, item) => sum + item.total);
      double grandTotal = (targetBill.gameCharge ?? 0) + ordersTotal + (targetBill.manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount));
      double finalAmount = math.max(0.0, grandTotal - (targetBill.discountAmount ?? 0.0));
      
      try {
        await ref.read(gamesRepositoryProvider).updatePendingBillOrders(
          targetBill, 
          newOrders,
          ordersTotal,
          grandTotal,
          finalAmount
        );
        // Force pop and refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added! Refreshing...'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
'''

content = content.replace("  @override\n  Widget build(BuildContext context) {", new_method + "  Widget build(BuildContext context) {")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched combined_settlement_screen.dart with Add Item')
