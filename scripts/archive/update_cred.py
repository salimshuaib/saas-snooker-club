import re

def update_credit():
    path = 'lib/features/credit/data/credit_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update imports
    if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
        content = content.replace("import 'package:cloud_firestore/cloud_firestore.dart';", "import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:snooker_club/features/team/providers/team_providers.dart';\nimport 'package:snooker_club/features/team/domain/models/staff_member.dart';")

    # 2. Add Ref and currentStaff
    repo_def = """class CreditRepository {
  final FirebaseFirestore _firestore;

  CreditRepository(this._firestore);"""
  
    new_repo_def = """class CreditRepository {
  final FirebaseFirestore _firestore;
  final Ref? _ref;

  CreditRepository(this._firestore, {Ref? ref}) : _ref = ref;

  StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;"""
    content = content.replace(repo_def, new_repo_def)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_credit()
