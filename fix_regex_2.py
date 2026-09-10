import re

path = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(path, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Replace any sequence of non-alphanumeric chars between a single quote and $ with ₹
# Example: 'Ã¢â€šÂ¹${_ordersTotal... -> '₹${_ordersTotal...
content = re.sub(r"\'[^a-zA-Z0-9\s_\.\,]+?\$", r"'₹$", content)
content = re.sub(r"prefixText:\s*\'[^a-zA-Z0-9\s_\.\,]+?\'", r"prefixText: '₹'", content)

# Fix the divider
content = re.sub(r'// [^A-Za-z0-9\s]+ (.*?) [^A-Za-z0-9\s]+', r'// ── \1 ──', content)
content = re.sub(r'Confirm Payment \([^a-zA-Z0-9\s_\.\,]+?\$', r'Confirm Payment (₹$', content)
content = re.sub(r"Split amounts \([^a-zA-Z0-9\s_\.\,]+?\) do not equal the grand total \([^a-zA-Z0-9\s_\.\,]+?\)", r"Split amounts (₹) do not equal the grand total (₹)", content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Replaced currencies")
