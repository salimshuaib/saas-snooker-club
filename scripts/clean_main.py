import sys

path = 'lib/main_production.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Remove the self-healing script block
content = re.sub(r'  // One-time fix for broken tables.*?  } catch \(e\) \{\n    print\(\'Fix failed: \'\);\n  \}\n\n', '', content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Removed self-healing script')
