import os
path = 'android/settings.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    'id("com.google.gms.google-services") version "4.4.2" apply false',
    'id("com.google.gms.google-services") version "4.4.2" apply false\n    id("com.google.firebase.crashlytics") version "3.0.2" apply false'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
