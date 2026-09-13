import os

filepath = 'lib/features/games/presentation/screens/game_activity_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """                            ...grouped[sortedKeys[i]]!.map(
                              (t) => GameActivityCard(table: t),
                            ),"""

new_code = """                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (MediaQuery.sizeOf(context).width > 800) {
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: grouped[sortedKeys[i]]!.map(
                                      (t) => SizedBox(
                                        width: 380,
                                        child: GameActivityCard(table: t),
                                      ),
                                    ).toList(),
                                  );
                                }
                                return Column(
                                  children: grouped[sortedKeys[i]]!.map(
                                    (t) => GameActivityCard(table: t),
                                  ).toList(),
                                );
                              },
                            ),"""

if old_code in text:
    text = text.replace(old_code, new_code)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS")
else:
    print("FAILED TO FIND CODE BLOCK")
