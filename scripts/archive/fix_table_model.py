import re

def fix_game_models():
    with open('lib/features/games/domain/models/game_models.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Clean TableModel
    # copyWith arguments
    content = re.sub(r'String\? createdByUserId,\s*String\? createdByName,\s*String\? updatedByUserId,\s*String\? updatedByName,\s*', '', content)
    # copyWith return constructor
    content = re.sub(r'createdByUserId: createdByUserId \?\? this\.createdByUserId,\s*createdByName: createdByName \?\? this\.createdByName,\s*updatedByUserId: updatedByUserId \?\? this\.updatedByUserId,\s*updatedByName: updatedByName \?\? this\.updatedByName,\s*', '', content)
    # toMap Map entries
    content = re.sub(r"'createdByUserId': createdByUserId,\s*'createdByName': createdByName,\s*'updatedByUserId': updatedByUserId,\s*'updatedByName': updatedByName,\s*", '', content)
    # fromMap constructor
    content = re.sub(r'createdByUserId: map\[\'createdByUserId\'\] as String\?,\s*createdByName: map\[\'createdByName\'\] as String\?,\s*updatedByUserId: map\[\'updatedByUserId\'\] as String\?,\s*updatedByName: map\[\'updatedByName\'\] as String\?,\s*', '', content)
    
    with open('lib/features/games/domain/models/game_models.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_game_models()
    print("Done")
