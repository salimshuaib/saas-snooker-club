import re

def modify_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    import_stmt = "import 'package:snooker_club/features/team/presentation/screens/team_screen.dart';\n"
    if "team_screen.dart" not in content:
        last_import_idx = content.rfind("import ")
        end_of_last_import = content.find("\n", last_import_idx) + 1
        content = content[:end_of_last_import] + import_stmt + content[end_of_last_import:]

    team_route = """        GoRoute(
          path: RouteNames.team,
          builder: (context, state) => const TeamScreen(),
        ),"""
        
    if "RouteNames.team" not in content:
        root_routes_idx = content.find("GoRoute(\n        path: RouteNames.forceUpdate")
        if root_routes_idx != -1:
            content = content[:root_routes_idx] + team_route + "\n" + content[root_routes_idx:]
        else:
            print("Could not find forceUpdate route")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_file('lib/core/routes/app_router.dart')
    print("Done")
