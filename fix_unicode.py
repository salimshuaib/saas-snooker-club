import re
import os

files = [
    'lib/features/games/presentation/screens/billing_screen.dart',
    'lib/features/games/presentation/screens/table_details_screen.dart',
    'lib/features/games/presentation/widgets/payer_selection_widget.dart',
]

for path in files:
    if not os.path.exists(path): continue
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Replace literal ₹, â,¹, Ã¢â€šÂ¹ etc with \u20B9
    # We will just replace all currency-like weird chars before a $ with \u20B9
    content = re.sub(r"[₹âÃ‚¹\,]{1,5}\$", r"\\u20B9$", content)
    content = re.sub(r"prefixText:\s*\'[₹âÃ‚¹\,]{1,5}\'", r"prefixText: '\\u20B9'", content)
    content = re.sub(r"Confirm Payment \([₹âÃ‚¹\,]{1,5}\$", r"Confirm Payment (\\u20B9$", content)
    content = re.sub(r"Split amounts \([₹âÃ‚¹\,]{1,5}\) do not equal the grand total \([₹âÃ‚¹\,]{1,5}\)", r"Split amounts (\\u20B9) do not equal the grand total (\\u20B9)", content)

    # To be absolutely sure, just replace literally if they are still there
    content = content.replace('â,¹', r'\u20B9')
    content = content.replace('â‚¹', r'\u20B9')
    content = content.replace('Ã¢â€šÂ¹', r'\u20B9')
    content = content.replace('₹', r'\u20B9')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Escaped rupees")
