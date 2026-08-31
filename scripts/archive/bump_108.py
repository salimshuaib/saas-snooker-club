import os

path = 'pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('version: 1.0.7', 'version: 1.0.8')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
