import re

file_path = 'android/app/src/main/AndroidManifest.xml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_permissions = """
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
"""

if "FOREGROUND_SERVICE_MEDIA_PLAYBACK" not in content:
    content = content.replace('<uses-permission android:name="android.permission.USE_EXACT_ALARM" />', '<uses-permission android:name="android.permission.USE_EXACT_ALARM" />' + new_permissions)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
