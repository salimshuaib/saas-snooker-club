import os
path = 'android/app/build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('S&amp;B Manager', 'Sharma Billiards')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
