import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# find if (false) ...[  // Disabled: Race games no longer use point tracking
start_idx = content.find('if (false) ...[  // Disabled: Race games no longer use point tracking')
if start_idx != -1:
    end_idx = content.find('],', start_idx)
    content = content[:start_idx] + content[end_idx+2:]
    
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
