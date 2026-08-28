path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\core\routes\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Wrap all builder returns in TickerMode(enabled: true, child: ...)
# Be careful not to wrap things that don't return a widget directly, but all builders here use arrow functions or return statements.

def wrap_builder(match):
    prefix = match.group(1)
    widget_code = match.group(2)
    
    # Ignore if already wrapped
    if 'TickerMode' in widget_code:
        return match.group(0)
        
    return f"{prefix} const TickerMode(enabled: true, child: {widget_code}),"

content = re.sub(r'(builder:\s*\(context,\s*state\)\s*=>)\s*(const\s+[A-Za-z0-9_]+\(\)),', wrap_builder, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
