import sys

file_path = 'lib/features/games/presentation/screens/table_details_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """        if (continueFrame == true) {
          await Future.delayed(const Duration(milliseconds: 400));
          await ref
              .read(gameSessionControllerProvider.notifier)
              .updateGameRounds(
                game.id,
                updatedRounds,
                updatedRounds.length + 1,
                updatedRounds.length,
              );
          if (mounted && context.mounted) {"""

repl = """        if (continueFrame == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
          );
          try {
            await Future.delayed(const Duration(milliseconds: 400));
            await ref
                .read(gameSessionControllerProvider.notifier)
                .updateGameRounds(
                  game.id,
                  updatedRounds,
                  updatedRounds.length + 1,
                  updatedRounds.length,
                );
            await Future.delayed(const Duration(milliseconds: 500));
          } finally {
            if (context.mounted) Navigator.pop(context); // close loading
          }
          if (mounted && context.mounted) {"""

if target in content:
    content = content.replace(target, repl)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed table_details_screen.dart")
else:
    print("Target not found in table_details_screen.dart")
