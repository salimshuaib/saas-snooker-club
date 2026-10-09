import sys

path = 'lib/main_production.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

if "import 'package:cloud_firestore/cloud_firestore.dart';" not in content:
    content = "import 'package:cloud_firestore/cloud_firestore.dart';\n" + content
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Import added!')
