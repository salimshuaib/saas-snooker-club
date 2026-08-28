import os
import re

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            lines = content.split('\n')
            new_lines = []
            changed = False
            
            for line in lines:
                if 'AppLocalizations' in line and 'const ' in line:
                    # simplistic: just remove 'const ' from the line
                    # Note: this might break if const is used for something else on the same line,
                    # but usually it's fine for simple UI code.
                    new_line = line.replace('const ', '')
                    new_lines.append(new_line)
                    changed = True
                else:
                    new_lines.append(line)
                    
            if changed:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write('\n'.join(new_lines))
                print(f"Removed const in {filepath}")
