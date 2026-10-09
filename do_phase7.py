import os

filepath = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('final isOverdue = age.inHours >= 24;', 'final isOverdue = age.inDays >= 7;')
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

filepath = 'lib/features/games/presentation/widgets/pending_bills_icon_badge.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_build = '''  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingBillsCountProvider);
    final theme = Theme.of(context);'''
    
new_build = '''  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingBillsCountProvider);
    final bills = ref.watch(pendingBillsProvider).asData?.value ?? [];
    final hasOverdue = bills.any((b) => DateTime.now().difference(b.markedPendingAt ?? DateTime.now()).inDays >= 7);
    final theme = Theme.of(context);'''
    
content = content.replace(old_build, new_build)

content = content.replace('color: Colors.orange,', 'color: hasOverdue ? AppColors.error : Colors.orange,')

if "import 'package:snooker_club/core/theme/app_colors.dart';" not in content:
    content = "import 'package:snooker_club/core/theme/app_colors.dart';\n" + content

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('Phase 7 complete')
