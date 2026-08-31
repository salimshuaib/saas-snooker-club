import os
path = 'android/app/build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('resValue("string", "app_name", "Sharma Billiards")', 'resValue("string", "app_name", "S&B Manager")')
c = c.replace('resValue("string", "app_name", "[PREVIEW] Sharma Billiards")', 'resValue("string", "app_name", "[PREVIEW] S&B Manager")')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
