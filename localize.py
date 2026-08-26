import json
import os
import re

arb_path = 'lib/l10n/app_en.arb'
with open(arb_path, 'r', encoding='utf-8') as f:
    arb_data = json.load(f)

# Create a mapping from English string to arb key
# Exclude keys starting with @
mapping = {}
for key, value in arb_data.items():
    if not key.startswith('@'):
        mapping[value] = key

# We want to replace Text('Value') or Text("Value") with Text(AppLocalizations.of(context)!.key)
# We need to also add the import if a replacement is made:
# import 'package:flutter_gen/gen_l10n/app_localizations.dart'; or just 'package:snooker_club/l10n/app_localizations.dart'
# Wait, based on l10n.yaml output-localization-file: app_localizations.dart in lib/l10n, the import should be:
# import 'package:snooker_club/l10n/app_localizations.dart';

import_statement = "import 'package:snooker_club/l10n/app_localizations.dart';"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    changed = False

    for eng_str, arb_key in mapping.items():
        # Match Text('eng_str') or Text("eng_str")
        # Be careful with quotes and exact matches
        # We can use a regex to find Text('exact')
        
        # single quotes
        pattern_sq = r"Text\(\s*'" + re.escape(eng_str) + r"'\s*\)"
        repl_sq = f"Text(AppLocalizations.of(context)!.{arb_key})"
        
        # double quotes
        pattern_dq = r'Text\(\s*"' + re.escape(eng_str) + r'"\s*\)'
        repl_dq = f"Text(AppLocalizations.of(context)!.{arb_key})"
        
        new_content, count1 = re.subn(pattern_sq, repl_sq, content)
        content = new_content
        new_content, count2 = re.subn(pattern_dq, repl_dq, content)
        content = new_content
        
        if count1 > 0 or count2 > 0:
            changed = True

    if changed:
        # add import if not there
        if import_statement not in content:
            # find first import and insert before it
            match = re.search(r'^import .*?;', content, re.MULTILINE)
            if match:
                content = content[:match.start()] + import_statement + '\n' + content[match.start():]
            else:
                content = import_statement + '\n' + content
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Done replacing text.")
