import os

filepath = 'lib/features/games/presentation/screens/game_activity_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """    final currentStaff = ref.watch(currentStaffProvider).value;
    final currentUserName = currentStaff?.name ?? club?.ownerName ?? 'Admin';"""

new_code = """    final currentStaff = ref.watch(currentStaffProvider).value;
    
    String currentUserName = currentStaff?.name ?? 'Admin';
    if (currentStaff?.role == StaffRole.owner || currentStaff == null) {
       final oName = club?.ownerName;
       if (oName != null && oName.isNotEmpty) {
         currentUserName = oName;
       }
    }
"""

text = text.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
