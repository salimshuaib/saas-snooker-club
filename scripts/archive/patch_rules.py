import re

with open('firestore.rules', 'r', encoding='utf-8') as f:
    content = f.read()

new_rule = '''      match /settings/{docId} {
        allow read: if true; // Public needs to read settings for booking website
        allow write: if belongsToClub(clubId) || isSuperAdmin();
      }'''

content = content.replace("match /tables/{tableId} {", new_rule + "\n\n      match /tables/{tableId} {")

with open('firestore.rules', 'w', encoding='utf-8') as f:
    f.write(content)
