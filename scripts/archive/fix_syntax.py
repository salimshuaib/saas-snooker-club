path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\presentation\screens\resource_management_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(\"Text('Error: \')\", \"Text('Error: \')\")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
