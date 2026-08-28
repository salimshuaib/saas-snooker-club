path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\dashboard\presentation\screens\main_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Remove the ref.listen from build
content = re.sub(
    r'    ref\.listen<String\?>\(clubIdProvider, \(previous, next\) \{\s*if \(next != null\) \{\s*_triggerInitialization\(next\);\s*\}\s*\}\);\s*',
    '',
    content
)

# Add listenManual to initState
init_state_new = '''  @override
  void initState() {
    super.initState();
    ref.listenManual<String?>(clubIdProvider, (previous, next) {
      if (next != null) {
        _triggerInitialization(next);
      }
    }, fireImmediately: true);
  }'''

content = re.sub(
    r'  @override\s*void initState\(\) \{\s*super\.initState\(\);\s*\}',
    init_state_new,
    content
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
