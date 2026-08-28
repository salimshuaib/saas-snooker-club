import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''      if (!context.mounted) return;
      context.pushNamed(
        AppRoutes.billing,
        extra: game.copyWith(playerPoints: fakePoints),
      );
      return;'''

replacement = '''      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BillingScreen(session: game.copyWith(playerPoints: fakePoints)),
        ),
      );
      return;'''

content = content.replace(target, replacement)

# also remove the imports I added
content = content.replace("import 'package:go_router/go_router.dart';\n", "")
content = content.replace("import 'package:snooker_club/core/routes/app_router.dart';\n", "")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
