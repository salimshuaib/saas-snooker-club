import sys

file_path = 'lib/features/dashboard/presentation/screens/main_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import re
content = re.sub(r'    // Keep critical providers active.*?\n(?:    //.*?\n)*', '', content, flags=re.DOTALL)
content = re.sub(r'    ref\.watch\(.*?\);\n', '', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed ref.watch from MainScreen")
