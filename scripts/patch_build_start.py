import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_build = '''  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalSelectedAmount;
    final appSettings = ref.watch(appSettingsProvider);'''

new_build = '''  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalSelectedAmount;
    final totalGameCharges = _totalGameCharges;
    final totalOrders = _totalOrders;
    final totalManualGames = _totalManualGames;
    final totalDiscount = _totalDiscount;
    final unroundedTotal = totalGameCharges + totalOrders + totalManualGames - totalDiscount;
    final totalRounding = total - unroundedTotal;
    final appSettings = ref.watch(appSettingsProvider);'''

content = content.replace(old_build, new_build)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched build start in combined settlement screen')
