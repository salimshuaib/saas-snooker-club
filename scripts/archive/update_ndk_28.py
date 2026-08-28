import os

path = 'android/app/build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    'ndkVersion = "27.1.12297006"',
    'ndkVersion = "28.2.13676358"'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
