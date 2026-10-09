import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _localBills to state
init_state_old = '''  @override
  void initState() {
    super.initState();
    // Default to all selected
    for (final bill in widget.initialBills) {'''

init_state_new = '''  late List<GameSession> _localBills;

  @override
  void initState() {
    super.initState();
    _localBills = List.from(widget.initialBills);
    // Default to all selected
    for (final bill in _localBills) {'''

content = content.replace(init_state_old, init_state_new)

# Replace all widget.initialBills with _localBills inside the state class
# First, split the file at the end of the widget class
parts = content.split('class _CombinedSettlementScreenState')
state_class = 'class _CombinedSettlementScreenState' + parts[1].replace('widget.initialBills', '_localBills')
content = parts[0] + state_class

# Now update the _showAddOrderSheet method to update _localBills instead of pop
old_pop = '''        // Force pop and refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added! Refreshing...'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);'''

new_pop = '''        // Update local state
        setState(() {
          final index = _localBills.indexWhere((b) => b.id == targetBill.id);
          if (index != -1) {
            _localBills[index] = targetBill.copyWith(
              orders: newOrders,
              ordersTotal: ordersTotal,
              grandTotal: grandTotal,
              roundedAmount: finalAmount,
              finalAmount: finalAmount,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added!'), backgroundColor: Colors.green),
        );'''

content = content.replace(old_pop, new_pop)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched combined_settlement_screen.dart to use local bills and avoid popping')
