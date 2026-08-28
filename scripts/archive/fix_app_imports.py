import sys
import re

file_path = 'lib/app.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the imports appended at the end
match = re.search(r'import \'package:snooker_club/features/games/providers/games_providers\.dart\';.*', content, re.DOTALL)
if match:
    imports_and_class = match.group(0)
    # Remove it from the end
    content = content[:match.start()]
    
    # Split imports and class
    parts = imports_and_class.split('class _GlobalProviderKeeper')
    imports = parts[0]
    class_code = 'class _GlobalProviderKeeper' + parts[1]
    
    # Prepend imports to the top of the file
    content = imports + '\n' + content + '\n' + class_code
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed imports in app.dart")
