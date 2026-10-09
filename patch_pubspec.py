import re

file_path = 'pubspec.yaml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("permission_handler: ^13.0.2", "permission_handler: ^11.3.1")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
