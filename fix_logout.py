import os

filepath = 'lib/features/settings/presentation/screens/settings_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """                  onPressed: () async {
                    final confirmed = await LogoutDialog.show(context);
                    if (confirmed == true && context.mounted) {
                      try {
                        await ref.read(authRepositoryProvider).signOut();"""

new_code = """                  onPressed: () async {
                    final confirmed = await LogoutDialog.show(context);
                    if (confirmed == true && context.mounted) {
                      // Allow dialog pop animation to complete before routing away to prevent CanvasKit crash
                      await Future.delayed(const Duration(milliseconds: 100));
                      try {
                        if (context.mounted) {
                          await ref.read(authRepositoryProvider).signOut();
                        }"""

text = text.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
