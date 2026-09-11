import sys

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Initialize with Default 1 and Default 2
old_init_state = '''  // Players
  final List<PlayerSelection?> _teamASelections = [null];
  final List<PlayerSelection?> _teamBSelections = [null];'''

new_init_state = '''  // Players
  final List<PlayerSelection?> _teamASelections = [PlayerSelection(name: 'Default 1')];
  final List<PlayerSelection?> _teamBSelections = [PlayerSelection(name: 'Default 2')];'''
text = text.replace(old_init_state, new_init_state)

# Default player bypass
old_logic = '''        final allProfiles = ref.read(allCustomersProvider).value ?? [];
        final Map<String, String> resolvedIdentities = {};
        final List<String> finalPlayerIds = [];
        final List<PlayerProfile> newProfilesToCreate = [];
  
        for (final p in combinedSelections) {
          if (p.id != null) {'''

new_logic = '''        final allProfiles = ref.read(allCustomersProvider).value ?? [];
        final Map<String, String> resolvedIdentities = {};
        final List<String> finalPlayerIds = [];
        final List<PlayerProfile> newProfilesToCreate = [];
  
        for (final p in combinedSelections) {
          if (p.name.trim().toLowerCase().startsWith('default')) {
            // SKIP profile creation, treat as anonymous
            resolvedIdentities[p.name] = 'anonymous_default_id_';
            continue;
          }
          if (p.id != null) {'''
          
text = text.replace(old_logic, new_logic)

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)
