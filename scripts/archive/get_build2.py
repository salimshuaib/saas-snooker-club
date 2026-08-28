import re
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Extract from Widget build(BuildContext context) { of _BillingScreenState
match = re.search(r'Widget build\(BuildContext context\) \{.*?(?=class _SectionCard)', content, re.DOTALL)
if match:
    # Print the first 2000 chars of the build method
    print(match.group(0)[:3000])
else:
    print("Not found")

