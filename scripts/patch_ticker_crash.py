import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will find the exact string to replace using python.
import re

content = re.sub(
r'''        child: PendingBillCustomerSheet\(
          onCustomerSelected: \(id, name\) async \{
            final appSettings = ref\.read\(appSettingsProvider\);(.*?)\n            if \(ctx\.mounted\) \{
              Navigator\.of\(ctx\)\.pop\(\);
            \}
          \},
        \),''',
r'''        child: PendingBillCustomerSheet(
          onCustomerSelected: (id, name) async {
            Navigator.of(ctx).pop();
            // Wait for the bottom sheet closing animation to finish
            // This prevents Riverpod TickerMode exceptions when the game card unmounts
            await Future.delayed(const Duration(milliseconds: 300));
            
            final appSettings = ref.read(appSettingsProvider);\1
          },
        ),''',
content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Applied delay fix")
