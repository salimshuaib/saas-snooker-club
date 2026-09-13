import os
import glob

for root, dirs, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                for i, line in enumerate(lines):
                    if "'Admin'" in line or '"Admin"' in line:
                        print(f"{path}:{i+1}: {line.strip()}")
