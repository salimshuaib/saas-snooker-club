import sys
import re

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('_firestore', '_db')
content = content.replace('const Uuid().v4()', 'DateTime.now().millisecondsSinceEpoch.toString()')

content = re.sub(
    r'creditRepo\.appendCreditToBatch\(\s*batch:\s*batch,\s*clubId:\s*clubId,\s*customerId:\s*(.*?),\s*amount:\s*(.*?),\s*referenceId:\s*(.*?),\s*type:\s*CreditTransactionType\.game,\s*description:\s*(.*?),\s*staffId:\s*(.*?),\s*staffName:\s*(.*?)\s*\);',
    r'''await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: \1,
              amount: \2,
              type: CreditTransactionType.game,
              referenceId: \3,
              title: 'Pending Bill',
              paymentMethod: PaymentMethod.credit,
            );''',
    content,
    flags=re.DOTALL
)

content = content.replace('final staff = _enrichWithStaff({});', 'final staff = <String, dynamic>{};')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
