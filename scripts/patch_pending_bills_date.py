import sys

path = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:snooker_club/core/widgets/shared/date_navigation_header.dart';"
if import_stmt not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)

# Add _selectedDate to state
state_old = '''class _PendingBillsScreenState extends ConsumerState<PendingBillsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();'''
state_new = '''class _PendingBillsScreenState extends ConsumerState<PendingBillsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();'''
content = content.replace(state_old, state_new)

# Add filtering by date
old_filtering = '''          final filteredBills = _searchQuery.isEmpty
              ? bills
              : bills.where((b) {
                  final name = b.pendingBillCustomerName?.toLowerCase() ?? '';
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();'''
new_filtering = '''          final targetDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
                }).toList();'''
content = content.replace(old_filtering, new_filtering)

# Add DateNavigationHeader to UI
old_ui = '''          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField('''
new_ui = '''          return Column(
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
                child: TextField('''
content = content.replace(old_ui, new_ui)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Patched pending_bills_screen.dart')
