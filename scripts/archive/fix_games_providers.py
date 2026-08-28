import sys

file_path = 'lib/features/games/providers/games_providers.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# We want to find state = AsyncValue.error(e, st); and add ethrow; after it if it doesn't already have one.
lines = content.split('\n')
new_lines = []
for i, line in enumerate(lines):
    new_lines.append(line)
    if 'state = AsyncValue.error(e, st);' in line:
        # Check if the next line is not rethrow
        if i + 1 < len(lines) and 'rethrow;' not in lines[i+1]:
            # Add rethrow with the same indentation
            indent = line[:len(line) - len(line.lstrip())]
            new_lines.append(indent + 'rethrow;')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))
print("Added rethrow to games_providers.dart")
