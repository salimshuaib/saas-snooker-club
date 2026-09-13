import os

files = [
    'lib/features/games/data/games_repository.dart',
    'lib/features/credit/data/credit_repository.dart',
    'lib/features/quick_sales/data/quick_sales_repository.dart',
    'lib/features/inventory/data/inventory_repository.dart'
]

old_getter = """  String get currentUserName {
    final staff = currentStaff;
    if (staff != null) return staff.name;
    try {
      final club = _ref?.read(clubProfileProvider).value;
      if (club != null) return club.ownerName;
    } catch (_) {}
    return 'Admin';
  }"""

new_getter = """  String get currentUserName {
    try {
      final club = _ref?.read(clubProfileProvider).value;
      final staff = currentStaff;
      if (staff != null) {
        if (staff.role == StaffRole.owner && club != null && club.ownerName.isNotEmpty) {
          return club.ownerName;
        }
        if (staff.name.isNotEmpty && staff.name != 'Admin' && staff.name != 'Club Owner') {
          return staff.name;
        }
      }
      if (club != null && club.ownerName.isNotEmpty) return club.ownerName;
    } catch (_) {}
    return 'Admin';
  }"""

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    
    text = text.replace(old_getter, new_getter)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
