import os

def fix_dropdown():
    path = 'lib/features/games/presentation/widgets/game_setup_sheet.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace('DropdownButtonFormField<GameType>(\\n                  isExpanded: true,', 'DropdownButtonFormField<GameType>(\n                  isExpanded: true,')
    content = content.replace('DropdownButtonFormField<BillingType>(\\n                              isExpanded: true,', 'DropdownButtonFormField<BillingType>(\n                              isExpanded: true,')
    content = content.replace('DropdownButtonFormField<MatchType>(\\n                              isExpanded: true,', 'DropdownButtonFormField<MatchType>(\n                              isExpanded: true,')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_dropdown()
