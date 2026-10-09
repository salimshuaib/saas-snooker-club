import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

start_sig = '  Future<void> _showAddOrderSheet() async {'
end_sig = '  @override\\n  Widget build(BuildContext context) {'

idx = content.find(start_sig)
if idx != -1:
    idx2 = content.find(end_sig, idx)
    if idx2 != -1:
        method = content[idx:idx2]
        content = content[:idx] + content[idx2:]
        
        target = '  @override\\n  Widget build(BuildContext context) {'
        # Find the FIRST build method (which belongs to _CombinedSettlementScreenState)
        idx_target = content.find(target)
        if idx_target != -1:
            content = content[:idx_target] + method + content[idx_target:]
            
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content.replace('\\\\n', '\\n'))
            print('Fixed combined_settlement_screen.dart manually')
