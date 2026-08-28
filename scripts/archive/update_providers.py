import re
import os

def modify_providers(file_path, repo_class, provider_name):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    import_stmt = "import 'package:snooker_club/features/team/providers/team_providers.dart';\n"
    if "features/team/providers/team_providers.dart" not in content:
        last_import_idx = content.rfind("import ")
        end_of_last_import = content.find("\n", last_import_idx) + 1
        content = content[:end_of_last_import] + import_stmt + content[end_of_last_import:]

    target = f"""final {provider_name} = Provider<{repo_class}>((ref) {{
  return {repo_class}();
}});"""

    replacement = f"""final {provider_name} = Provider<{repo_class}>((ref) {{
  final staff = ref.watch(currentStaffProvider).valueOrNull;
  return {repo_class}(currentStaff: staff);
}});"""

    if target in content:
        content = content.replace(target, replacement)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_providers('lib/features/games/providers/games_providers.dart', 'GamesRepository', 'gamesRepositoryProvider')
    modify_providers('lib/features/quick_sales/providers/quick_sales_providers.dart', 'QuickSalesRepository', 'quickSalesRepositoryProvider')
    print("Done")
