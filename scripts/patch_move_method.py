import sys
import re

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the method from wherever it was inserted
idx_start = content.find('  Future<void> _showAddOrderSheet() async {')
idx_end = content.find('  @override\n  Widget build(BuildContext context) {', idx_start)
if idx_start != -1 and idx_end != -1:
    method_content = content[idx_start:idx_end]
    content = content[:idx_start] + content[idx_end:]

# Add it right before the build method of _CombinedSettlementScreenState
state_build_idx = content.find('  Widget build(BuildContext context) {')
# To ensure we get the right one, let's search for "final theme = Theme.of(context);" which is inside it
if state_build_idx != -1:
    content = content[:state_build_idx-13] + method_content + content[state_build_idx-13:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Moved _showAddOrderSheet to the correct class')
