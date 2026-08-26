with open('lib/features/credit/providers/credit_providers.dart', 'r', encoding='utf-8') as f:
    prov = f.read()

new_logic = '''
class CustomerSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  
  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
    }
  }
  
  void clear() => state = {};
}

final customerSelectionProvider = NotifierProvider<CustomerSelectionNotifier, Set<String>>(CustomerSelectionNotifier.new);

  Future<void> deleteMultipleCustomers(Set<String> customerIds) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(creditRepositoryProvider);
      for (final id in customerIds) {
        await repo.deletePlayerProfile(id);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
'''
if 'CustomerSelectionNotifier' not in prov:
    prov = prov.replace('  Future<void> deleteCustomer(String customerId) async {', new_logic + '\n  Future<void> deleteCustomer(String customerId) async {')
    with open('lib/features/credit/providers/credit_providers.dart', 'w', encoding='utf-8') as f:
        f.write(prov)
    print("Provider patched")
