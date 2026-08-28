import re

def main():
    file_path = 'lib/core/routes/app_router.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Step 1: Remove _gamesNavigatorKey, _inventoryNavigatorKey, _moreNavigatorKey from top
    content = re.sub(r'final GlobalKey<NavigatorState> _gamesNavigatorKey =\s*GlobalKey<NavigatorState>\(debugLabel: \'games\'\);\n', '', content)
    content = re.sub(r'final GlobalKey<NavigatorState> _inventoryNavigatorKey =\s*GlobalKey<NavigatorState>\(debugLabel: \'inventory\'\);\n', '', content)
    content = re.sub(r'final GlobalKey<NavigatorState> _moreNavigatorKey =\s*GlobalKey<NavigatorState>\(debugLabel: \'more\'\);\n', '', content)

    # Step 2: Add _historyNavigatorKey
    content = re.sub(r'final GlobalKey<NavigatorState> _dashboardNavigatorKey =\s*GlobalKey<NavigatorState>\(debugLabel: \'dashboard\'\);\n',
                     'final GlobalKey<NavigatorState> _dashboardNavigatorKey =\n    GlobalKey<NavigatorState>(debugLabel: \'dashboard\');\nfinal GlobalKey<NavigatorState> _historyNavigatorKey =\n    GlobalKey<NavigatorState>(debugLabel: \'history\');\n', content)

    # Step 3: We need to pull out the routes from the branches.
    # I will replace the entire StatefulShellRoute block with a new one that only has Dashboard and History branches.
    # Then I will append Games, Inventory, More as flat GoRoutes at the end of the root routes list.
    
    # First, let's extract the table details block
    # It's better to just do string replacements for the whole StatefulShellRoute block.

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
