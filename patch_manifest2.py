import re

file_path = 'android/app/src/main/AndroidManifest.xml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'(<uses-permission android:name="android\.permission\.VIBRATE"\s*/>)', 
                 r'\1\n    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
