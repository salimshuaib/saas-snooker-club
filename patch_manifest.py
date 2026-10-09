import re

file_path = 'android/app/src/main/AndroidManifest.xml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" not in content:
    content = content.replace('<uses-permission android:name="android.permission.VIBRATE"/>', '<uses-permission android:name="android.permission.VIBRATE"/>\n    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
