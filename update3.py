import re

def fix():
    path = 'lib/features/history/presentation/screens/transaction_history_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find where slivers: [ starts
    start_idx = content.find('slivers: [')
    if start_idx != -1:
        # Find the next Game Transactions Header
        end_idx = content.find('// â”€â”€â”€ Game Transactions Header â”€â”€â”€', start_idx)
        if end_idx != -1:
            # Replace everything between slivers: [ and Game Transactions Header with just slivers: [
            content = content[:start_idx] + 'slivers: [\n                ' + content[end_idx:]
            
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix()
