import os

path = 'pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open(path, 'w', encoding='utf-8') as f:
    for line in lines:
        if line.startswith('version:'):
            f.write('version: 1.0.5\n')
        else:
            f.write(line)
