import os
import re

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # replace const Text(AppLocalizations with Text(AppLocalizations
            # replace const [ Text(AppLocalizations... ] with [ Text(AppLocalizations... ] ? No, if it's const [], we have to remove const from the array if all elements are not const, this is harder.
            
            new_content = re.sub(r'const\s+Text\(AppLocalizations', r'Text(AppLocalizations', content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed const in {filepath}")
