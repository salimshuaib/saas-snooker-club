with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

idx = -1
for i in range(len(lines)):
    if '@override' in lines[i] and i+1 < len(lines) and 'Widget build(BuildContext context)' in lines[i+1]:
        idx = i
        break

if idx != -1:
    with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(lines[:idx])
        
