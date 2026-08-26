import re

def update_cred_providers():
    path = 'lib/features/credit/providers/credit_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_provider = """final pendingTransactionsProvider = StreamProvider.family<List<CreditTransaction>, String>((ref, customerId) {
  return ref.watch(creditRepositoryProvider).watchPendingTransactions(customerId);
});

final allTransactionsProvider = StreamProvider.family<List<CreditTransaction>, String>((ref, customerId) {
  return ref.watch(creditRepositoryProvider).watchAllTransactions(customerId);
});"""
    content = content.replace("final pendingTransactionsProvider = StreamProvider.family<List<CreditTransaction>, String>((ref, customerId) {\n  return ref.watch(creditRepositoryProvider).watchPendingTransactions(customerId);\n});", new_provider)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_cred_providers()
