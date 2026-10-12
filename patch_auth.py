import re

file_path = 'lib/features/authentication/data/auth_repository.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the post-login try catch block that initializes push service
    # and replace `await pushService.initialize();` with `await pushService.requestPermission();`
    content = content.replace("await pushService.initialize();", "await pushService.requestPermission();")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched auth_repository.dart")
except FileNotFoundError:
    print("No auth_repository.dart found")
