path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\data\settings_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Insert before the last closing brace
last_brace_index = content.rfind('}')
if last_brace_index != -1:
    content = content[:last_brace_index] + '  Future<void> migrateTablesPricing() async {}\n' + content[last_brace_index:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
