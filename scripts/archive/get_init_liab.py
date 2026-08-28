import re
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# find _initializeLiabilities
match = re.search(r'void _initializeLiabilities\(\) \{.*?(?=void _handlePayment\(\) )', content, re.DOTALL)
if match:
    print(match.group(0)[:3000])
else:
    print("Not found")

