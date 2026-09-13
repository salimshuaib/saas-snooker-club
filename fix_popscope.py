import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_end = """      ),
    );
  }

  Widget _buildSplitLiabilityTable(ThemeData theme) {"""
new_end = """      ),
    ));
  }

  Widget _buildSplitLiabilityTable(ThemeData theme) {"""

text = text.replace(old_end, new_end)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
