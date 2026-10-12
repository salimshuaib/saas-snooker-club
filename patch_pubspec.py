import re

file_path = 'pubspec.yaml'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_version = "version: 1.0.24+24"
    new_version = "version: 1.0.25+25"

    if old_version in content:
        content = content.replace(old_version, new_version)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Patched pubspec.yaml version to 1.0.25+25")
    else:
        print("Could not find exact version string to replace.")
except Exception as e:
    print(f"Error: {e}")
