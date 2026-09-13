import os

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    final employeeName = currentStaff?.name ?? clubAsync.value?.ownerName ?? 'Admin';"""

new_code = """    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    String employeeName = currentStaff?.name ?? 'Admin';
    if (currentStaff?.role == StaffRole.owner || currentStaff == null || employeeName == 'Admin' || employeeName == 'Club Owner') {
       final oName = clubAsync.value?.ownerName;
       if (oName != null && oName.isNotEmpty) {
         employeeName = oName;
       }
    }"""

if old_code in text:
    text = text.replace(old_code, new_code)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
else:
    print("Dashboard screen old code not found")
