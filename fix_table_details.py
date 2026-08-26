import sys

file_path = 'lib/features/games/presentation/screens/table_details_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''        final updatedRounds = [...game.rounds, newRound];

        if (continueFrame == true) {
          await ref'''

replacement = '''        final updatedRounds = [...game.rounds, newRound];

        if (continueFrame == true) {
          await Future.delayed(const Duration(milliseconds: 400));
          await ref'''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced table_details_screen frame update")
else:
    print("Target not found in table_details_screen")
