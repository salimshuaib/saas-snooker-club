def fix_repo():
    with open('lib/features/team/data/team_repository.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("throw AppException(e.message ?? 'Failed to create staff account');", 
                              "throw AuthException(message: e.message ?? 'Failed to create staff account');")
    content = content.replace("throw AppException('An unexpected error occurred while creating the account.');", 
                              "throw UnknownException(message: 'An unexpected error occurred while creating the account.');")
    with open('lib/features/team/data/team_repository.dart', 'w', encoding='utf-8') as f:
        f.write(content)

def fix_screen():
    with open('lib/features/team/presentation/screens/team_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(".valueOrNull", ".value")
    content = content.replace("final theme = Theme.of(context);", "")
    with open('lib/features/team/presentation/screens/team_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

def fix_more():
    with open('lib/features/dashboard/presentation/screens/more_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(".valueOrNull", ".value")
    with open('lib/features/dashboard/presentation/screens/more_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

def fix_providers():
    with open('lib/features/team/providers/team_providers.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(".valueOrNull", ".value")
    with open('lib/features/team/providers/team_providers.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_repo()
    fix_screen()
    fix_more()
    fix_providers()
    print("Done")
