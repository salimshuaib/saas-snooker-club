import os

filepath = 'lib/features/inventory/data/inventory_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

import_statement = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';"""

getters = """
  StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;

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

if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in text:
    text = text.replace("import 'package:cloud_firestore/cloud_firestore.dart';", "import 'package:cloud_firestore/cloud_firestore.dart';\n" + import_statement)

if "final Ref? _ref;" not in text:
    text = text.replace("final String? clubId;", "final Ref? _ref;\n  final String? clubId;")
    text = text.replace("InventoryRepository(this._firestore, {this.clubId});", "InventoryRepository(this._firestore, {Ref? ref, this.clubId}) : _ref = ref;\n" + getters)
    
text = text.replace("required String employeeName,", "String employeeName = 'Admin',")
text = text.replace("employeeName: employeeName,", "employeeName: currentUserName,")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

# We also need to update InventoryRepository instantiation in providers
providers_path = 'lib/features/inventory/providers/inventory_providers.dart'
with open(providers_path, 'r', encoding='utf-8') as f:
    prov_text = f.read()

prov_text = prov_text.replace("return InventoryRepository(FirebaseFirestore.instance, clubId: clubId);", "return InventoryRepository(FirebaseFirestore.instance, ref: ref, clubId: clubId);")

with open(providers_path, 'w', encoding='utf-8') as f:
    f.write(prov_text)

