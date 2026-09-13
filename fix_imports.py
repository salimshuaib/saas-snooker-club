import os

filepath = 'lib/features/games/presentation/screens/game_activity_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

import_statement = "import 'package:snooker_club/features/team/domain/models/staff_member.dart';"

if import_statement not in text:
    text = text.replace("import 'package:snooker_club/features/team/providers/team_providers.dart';", "import 'package:snooker_club/features/team/providers/team_providers.dart';\n" + import_statement)

# Also update GameActivityScreen's logic to check for 'Admin' or 'Club Owner'
old_logic = """    if (currentStaff?.role == StaffRole.owner || currentStaff == null) {"""
new_logic = """    if (currentStaff?.role == StaffRole.owner || currentStaff == null || currentUserName == 'Admin' || currentUserName == 'Club Owner') {"""
text = text.replace(old_logic, new_logic)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

if import_statement not in text:
    text = text.replace("import 'package:snooker_club/features/team/providers/team_providers.dart';", "import 'package:snooker_club/features/team/providers/team_providers.dart';\n" + import_statement)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

