import re

def modify_games_repo(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the startGame method where the initial save happens
    if 'session.copyWith(' in content and 'createdByUserId: currentStaff?.id,' not in content:
        # For start game
        start_game_idx = content.find('Future<void> startGame(')
        if start_game_idx != -1:
            save_idx = content.find('await docRef.set(session.toMap());', start_game_idx)
            if save_idx != -1:
                replacement = """final updatedSession = session.copyWith(
      createdByUserId: currentStaff?.id,
      createdByName: currentStaff?.name,
      updatedByUserId: currentStaff?.id,
      updatedByName: currentStaff?.name,
    );
    await docRef.set(updatedSession.toMap());"""
                content = content.replace('await docRef.set(session.toMap());', replacement, 1)

    # For updateGame (used by billing, etc)
    if 'Future<void> updateGame(' in content:
        update_idx = content.find('Future<void> updateGame(')
        if update_idx != -1 and 'updatedByUserId: currentStaff?.id,' not in content:
            save_idx = content.find('await docRef.update(session.toMap());', update_idx)
            if save_idx != -1:
                replacement = """final updatedSession = session.copyWith(
      updatedByUserId: currentStaff?.id,
      updatedByName: currentStaff?.name,
    );
    await docRef.update(updatedSession.toMap());"""
                content = content.replace('await docRef.update(session.toMap());', replacement, 1)

    # For endGame
    if 'Future<void> endGame(' in content:
        end_idx = content.find('Future<void> endGame(')
        if end_idx != -1 and "updateMap['updatedByUserId'] = currentStaff?.id;" not in content:
            batch_update_idx = content.find("batch.update(_gamesRef.doc(session.id), updateMap);", end_idx)
            if batch_update_idx != -1:
                audit_injection = """
    updateMap['updatedByUserId'] = currentStaff?.id;
    updateMap['updatedByName'] = currentStaff?.name;
"""
                content = content[:batch_update_idx] + audit_injection + "    " + content[batch_update_idx:]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_games_repo('lib/features/games/data/games_repository.dart')
    print("Done")
