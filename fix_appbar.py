import os

filepath = 'lib/features/games/presentation/screens/game_activity_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

import_statement = "import 'package:snooker_club/features/team/providers/team_providers.dart';"

if import_statement not in text:
    text = text.replace("import 'package:snooker_club/core/providers/club_scope_provider.dart';", "import 'package:snooker_club/core/providers/club_scope_provider.dart';\n" + import_statement)

old_code = """    final tablesAsync = ref.watch(resolvedTablesProvider);
    final club = ref.watch(clubProfileProvider).value;
    final clubName = club?.clubName ?? 'Loading...';"""

new_code = """    final tablesAsync = ref.watch(resolvedTablesProvider);
    final club = ref.watch(clubProfileProvider).value;
    final clubName = club?.clubName ?? 'Loading...';
    
    final currentStaff = ref.watch(currentStaffProvider).value;
    final currentUserName = currentStaff?.name ?? club?.ownerName ?? 'Admin';"""

text = text.replace(old_code, new_code)
text = text.replace("'Admin',", "currentUserName,")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
