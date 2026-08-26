import re

# 1. Update CreditRepository
with open('lib/features/credit/data/credit_repository.dart', 'r', encoding='utf-8') as f:
    repo_code = f.read()

delete_method = '''
  Future<void> deletePlayerProfile(String customerId) async {
    if (AppConfig.guardWrite('CreditRepository.deletePlayerProfile')) return;
    final transSnap = await _transactionsRef(customerId).get();
    for (final doc in transSnap.docs) {
      await doc.reference.delete();
    }
    final paymentsSnap = await _paymentsRef(customerId).get();
    for (final doc in paymentsSnap.docs) {
      await doc.reference.delete();
    }
    await _creditsRef.doc(customerId).delete();
  }
'''
if 'deletePlayerProfile(String customerId)' not in repo_code:
    repo_code = repo_code.replace('Future<void> savePlayerProfile(PlayerProfile profile) async {', delete_method + '\n  Future<void> savePlayerProfile(PlayerProfile profile) async {')
    with open('lib/features/credit/data/credit_repository.dart', 'w', encoding='utf-8') as f:
        f.write(repo_code)


# 2. Update CreditController
with open('lib/features/credit/providers/credit_providers.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

delete_ctrl = '''
  Future<void> deleteCustomer(String customerId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(creditRepositoryProvider).deletePlayerProfile(customerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
'''
if 'deleteCustomer(String customerId)' not in prov_code:
    prov_code = prov_code.replace('Future<void> mergeCustomers(String sourceId, String targetId) async {', delete_ctrl + '\n  Future<void> mergeCustomers(String sourceId, String targetId) async {')
    with open('lib/features/credit/providers/credit_providers.dart', 'w', encoding='utf-8') as f:
        f.write(prov_code)


# 3. Update CreditScreen
with open('lib/features/credit/presentation/screens/credit_screen.dart', 'r', encoding='utf-8') as f:
    screen_code = f.read()

if 'import \'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart\';' not in screen_code:
    screen_code = 'import \'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart\';\n' + screen_code

# Replace _CustomerCard StatelessWidget with ConsumerWidget
screen_code = screen_code.replace('class _CustomerCard extends StatelessWidget {', 'class _CustomerCard extends ConsumerWidget {')
screen_code = screen_code.replace('Widget build(BuildContext context) {', 'Widget build(BuildContext context, WidgetRef ref) {')

# Add the delete button
button_code = '''
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyHelper.formatWhole(customer.outstandingAmount, currency),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final verified = await AdminPasscodeDialog.verify(
                            context, ref,
                            subtitle: 'Enter administrator passcode to delete this player profile.',
                          );
                          if (verified != true || !context.mounted) return;
                          
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Player?'),
                              content: Text('Are you sure you want to completely delete \ and all their credit history? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  child: const Text('DELETE'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(creditControllerProvider.notifier).deleteCustomer(customer.id);
                          }
                        },
                      ),
                    ],
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer.outstandingAmount > 0 ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer.outstandingAmount > 0 ? 'Outstanding' : 'Cleared',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customer.outstandingAmount > 0 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
'''

screen_code = re.sub(r'              Column\(\s*crossAxisAlignment: CrossAxisAlignment\.end,\s*children: \[\s*Text\(\s*CurrencyHelper\.formatWhole\(customer\.outstandingAmount, currency\),\s*style: theme\.textTheme\.titleMedium\?\.copyWith\(\s*color: AppColors\.error,\s*fontWeight: FontWeight\.bold,\s*\),\s*\),\s*const Gap\(4\),\s*Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 8, vertical: 4\),\s*decoration: BoxDecoration\(\s*color: customer\.outstandingAmount > 0 \? AppColors\.error\.withValues\(alpha: 0\.1\) : AppColors\.success\.withValues\(alpha: 0\.1\),\s*borderRadius: BorderRadius\.circular\(8\),\s*\),\s*child: Text\(\s*customer\.outstandingAmount > 0 \? \'Outstanding\' : \'Cleared\',\s*style: theme\.textTheme\.labelSmall\?\.copyWith\(\s*color: customer\.outstandingAmount > 0 \? AppColors\.error : AppColors\.success,\s*fontWeight: FontWeight\.bold,\s*\),\s*\),\s*\),\s*\],\s*\),', button_code, screen_code, flags=re.DOTALL)

with open('lib/features/credit/presentation/screens/credit_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_code)
