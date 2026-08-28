import os

path = 'android/app/build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    'ndkVersion = flutter.ndkVersion',
    'ndkVersion = "27.1.12297006"'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
