import re

file_path = 'lib/main_production.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("  // Initialize alarm package\n  \n  // Register background handler", "  // Initialize alarm package\n  await Alarm.init();\n  \n  // Register background handler")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
