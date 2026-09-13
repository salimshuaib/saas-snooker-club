import os
import re

files = [
    'lib/features/games/data/games_repository.dart',
    'lib/features/credit/data/credit_repository.dart',
    'lib/features/quick_sales/data/quick_sales_repository.dart'
]

import_statement = "import 'package:snooker_club/core/providers/club_scope_provider.dart';"

getters = """
  String get currentUserName {
    final staff = currentStaff;
    if (staff != null) return staff.name;
    try {
      final club = _ref?.read(clubProfileProvider).value;
      if (club != null) return club.ownerName;
    } catch (_) {}
    return 'Admin';
  }

  String get currentUserId {
    final staff = currentStaff;
    if (staff != null) return staff.id;
    try {
      final club = _ref?.read(clubProfileProvider).value;
      if (club != null) return club.ownerUid;
    } catch (_) {}
    return 'Unknown';
  }
"""

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    
    if import_statement not in text:
        text = text.replace("import 'package:cloud_firestore/cloud_firestore.dart';", "import 'package:cloud_firestore/cloud_firestore.dart';\n" + import_statement)
    
    if 'String get currentUserName' not in text:
        text = text.replace("StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;", "StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;\n" + getters)
        
    # Replace in games repo
    text = text.replace("currentStaff?.name ?? 'Admin'", "currentUserName")
    text = text.replace("currentStaff?.name ?? employeeName", "currentUserName")
    text = text.replace("currentStaff?.id ?? 'Unknown'", "currentUserId")
    
    # Specific for games repo audit log
    text = text.replace("'staffId': currentStaff?.id,", "'staffId': currentUserId == 'Unknown' ? null : currentUserId,")
    text = text.replace("'staffName': currentStaff?.name,", "'staffName': currentUserName,")
    
    # Specific for quick sales repo audit log
    text = text.replace("staffName = staff?.name;", "staffName = currentUserName;")
    text = text.replace("staffId = staff?.id;", "staffId = currentUserId == 'Unknown' ? null : currentUserId;")
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
