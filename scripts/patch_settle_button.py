import sys
import re

path = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the condition that hides the button when there's only 1 bill
content = content.replace('''                          if (customerBills.length > 1)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {''',
'''                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {''')

# Change the text of the button
content = content.replace("child: const Text('Settle All for this Customer')", "child: const Text('Settle Bill(s)')")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched button visibility')
