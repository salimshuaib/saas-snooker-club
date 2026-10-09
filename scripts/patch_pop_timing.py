import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_logic = """        child: PendingBillCustomerSheet(
          onCustomerSelected: (id, name) async {
            Navigator.of(ctx).pop();
            final appSettings = ref.read(appSettingsProvider);"""

new_logic = """        child: PendingBillCustomerSheet(
          onCustomerSelected: (id, name) async {
            final appSettings = ref.read(appSettingsProvider);"""

if old_logic in content:
    content = content.replace(old_logic, new_logic)
    print("Replaced pop at start")
else:
    print("WARNING: pop at start not found")

old_pop = """            await ref.read(gamesRepositoryProvider).markAsPendingBill(
              finalSession,
              customerId: id,
              customerName: name,
            );
          },
        ),"""

new_pop = """            await ref.read(gamesRepositoryProvider).markAsPendingBill(
              finalSession,
              customerId: id,
              customerName: name,
            );
            
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
          },
        ),"""

if old_pop in content:
    content = content.replace(old_pop, new_pop)
    print("Added pop at end")
else:
    print("WARNING: pop at end not found")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
