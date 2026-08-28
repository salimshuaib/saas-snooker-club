path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\widgets\game_setup_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''hint: 'Custom price per hour',''', '''hint: 'Custom price per minute',''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
