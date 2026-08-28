import re

def modify_repos():
    # 1. GamesRepository
    with open('lib/features/games/data/games_repository.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Add ref import
    if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
        content = content.replace("import 'package:cloud_firestore/cloud_firestore.dart';", "import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:snooker_club/features/team/providers/team_providers.dart';")
        
    # Replace final StaffMember? currentStaff; with Ref and getter
    content = re.sub(r'final StaffMember\? currentStaff;\s*GamesRepository\(\{FirebaseFirestore\? db, this\.currentStaff\}\)', 
                     'final Ref? _ref;\n  GamesRepository({FirebaseFirestore? db, Ref? ref}) : _db = db ?? FirebaseFirestore.instance, _ref = ref;', content)
    content = content.replace('GamesRepository({FirebaseFirestore? db, this.currentStaff})', 'GamesRepository({FirebaseFirestore? db, Ref? ref}) : _db = db ?? FirebaseFirestore.instance, _ref = ref;')
    
    # Add getter
    if "StaffMember? get currentStaff =>" not in content:
        content = content.replace('CollectionReference get _tablesRef =>', 'StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;\n\n  CollectionReference get _tablesRef =>')

    with open('lib/features/games/data/games_repository.dart', 'w', encoding='utf-8') as f:
        f.write(content)


    # 2. QuickSalesRepository
    with open('lib/features/quick_sales/data/quick_sales_repository.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
        content = content.replace("import 'package:cloud_firestore/cloud_firestore.dart';", "import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:snooker_club/features/team/providers/team_providers.dart';")
        
    # Replace constructor
    content = re.sub(r'final StaffMember\? currentStaff;\s*QuickSalesRepository\(this\._firestore, \{this\.currentStaff\}\);', 
                     'final Ref? _ref;\n  QuickSalesRepository(this._firestore, {Ref? ref}) : _ref = ref;', content)
                     
    if "StaffMember? get currentStaff =>" not in content:
        content = content.replace('CollectionReference get _quickSalesRef =>', 'StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;\n\n  CollectionReference get _quickSalesRef =>')

    with open('lib/features/quick_sales/data/quick_sales_repository.dart', 'w', encoding='utf-8') as f:
        f.write(content)

    # 3. Update providers
    with open('lib/features/games/providers/games_providers.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = re.sub(r'final staff = ref\.watch\(currentStaffProvider\)\.value;\s*return GamesRepository\(currentStaff: staff\);', 
                     'return GamesRepository(ref: ref);', content)
    with open('lib/features/games/providers/games_providers.dart', 'w', encoding='utf-8') as f:
        f.write(content)

    with open('lib/features/quick_sales/providers/quick_sales_providers.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = re.sub(r'final staff = ref\.watch\(currentStaffProvider\)\.value;\s*return QuickSalesRepository\(ref\.watch\(firestoreServiceProvider\)\.db, currentStaff: staff\);', 
                     'return QuickSalesRepository(ref.watch(firestoreServiceProvider).db, ref: ref);', content)
    with open('lib/features/quick_sales/providers/quick_sales_providers.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_repos()
    print("Done")
