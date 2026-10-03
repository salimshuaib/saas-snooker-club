import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

class PendingBillCustomerSheet extends ConsumerStatefulWidget {
  final Function(String customerId, String customerName) onCustomerSelected;

  const PendingBillCustomerSheet({
    Key? key,
    required this.onCustomerSelected,
  }) : super(key: key);

  @override
  ConsumerState<PendingBillCustomerSheet> createState() =>
      _PendingBillCustomerSheetState();
}

class _PendingBillCustomerSheetState extends ConsumerState<PendingBillCustomerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<PlayerProfile> _filteredCustomers = [];
  bool _isCreatingNew = false;
  String _newCustomerName = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _filteredCustomers = ref.read(allCustomersProvider).asData?.value ?? [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final allCustomers = ref.read(allCustomersProvider).asData?.value ?? [];

    setState(() {
      _newCustomerName = _searchController.text.trim();
      if (query.isEmpty) {
        _filteredCustomers = allCustomers;
        _isCreatingNew = false;
      } else {
        _filteredCustomers = allCustomers.where((c) {
          return c.name.toLowerCase().contains(query);
        }).toList();

        _isCreatingNew = !_filteredCustomers
            .any((c) => c.name.toLowerCase() == query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersState = ref.watch(allCustomersProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mark as Pending Bill',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'Who is this pending bill for?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search or enter new customer name',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
          const Gap(16),
          Expanded(
            child: customersState.when(
              data: (allCustomers) {
                if (_filteredCustomers.isEmpty && !_isCreatingNew) {
                  return const Center(child: Text('No customers found.'));
                }

                return ListView(
                  shrinkWrap: true,
                  children: [
                    if (_isCreatingNew && _newCustomerName.isNotEmpty)
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_add),
                        ),
                        title: Text('Create "$_newCustomerName"'),
                        subtitle: const Text('New Customer'),
                        onTap: () {
                          widget.onCustomerSelected(_newCustomerName, _newCustomerName);
                        },
                      ),
                    ..._filteredCustomers.map((c) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              c.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: Text('ID: ${c.id.substring(0, 8)}'),
                          onTap: () {
                            widget.onCustomerSelected(c.id, c.name);
                          },
                        )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
