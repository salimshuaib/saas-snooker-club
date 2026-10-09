import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
import_str = "import 'package:cloud_firestore/cloud_firestore.dart';"
if import_str not in content:
    content = content.replace("import 'package:snooker_club/core/constants/firebase_constants.dart';", "import 'package:snooker_club/core/constants/firebase_constants.dart';\n" + import_str)

# Fix read
content = content.replace('_ref.read(creditRepositoryProvider)', '_ref!.read(creditRepositoryProvider)')

# Fix GameSession.fromMap(data, doc.id) -> this was in watchPendingBills? No wait, that was already fixed. Where is line 1716?
# It's probably in watchPendingBills that I restored from fix_repo.py
content = content.replace('GameSession.fromMap(doc.data(), doc.id)', '''(() {
            final data = doc.data();
            data['id'] = doc.id;
            return GameSession.fromMap(data);
          })()''')

# Fix manualGamesTotal and discountPercent.
# In settlePendingBill or markAsPendingBillWithSplits
content = content.replace('manualGamesTotal: (session.manualGamesTotal ?? 0.0) / players.length,', '')
content = content.replace('discountPercent: session.discountPercent,', '')
content = content.replace('discountPercent', 'discountAmount')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed remaining games_repository.dart errors')
