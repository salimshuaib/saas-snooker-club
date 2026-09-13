import os

filepath = 'lib/features/games/data/games_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace any occurrence of the corrupted unicode character with the correct Rupee symbol code
text = text.replace("â‚¹", "\\u20B9")
text = text.replace("Ã¢â€šÂ¹", "\\u20B9")
text = text.replace("â€šÂ¹", "\\u20B9")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
