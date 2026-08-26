import re
import os

def modify_file(file_path, repo_class):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    import_stmt = "import 'package:snooker_club/features/team/domain/models/staff_member.dart';\n"
    if "features/team/domain/models/staff_member.dart" not in content:
        last_import_idx = content.rfind("import ")
        end_of_last_import = content.find("\n", last_import_idx) + 1
        content = content[:end_of_last_import] + import_stmt + content[end_of_last_import:]

    if "final StaffMember? currentStaff;" not in content:
        db_target = "final FirebaseFirestore _db;"
        if db_target in content:
            content = content.replace(db_target, "final FirebaseFirestore _db;\n  final StaffMember? currentStaff;")
        
        init_target = f"{repo_class}({{FirebaseFirestore? db}})"
        if init_target in content:
            content = content.replace(init_target, f"{repo_class}({{FirebaseFirestore? db, this.currentStaff}})")
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_file('lib/features/games/data/games_repository.dart', 'GamesRepository')
    modify_file('lib/features/quick_sales/data/quick_sales_repository.dart', 'QuickSalesRepository')
    print("Done")
