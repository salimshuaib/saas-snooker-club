import re

def inject_identity():
    path = 'lib/features/games/data/games_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Define the identity enrichment snippet
    enrich_game_session = """  GameSession _enrichWithStaff(GameSession session, bool isCreate) {
    final staff = currentStaff;
    if (staff == null) return session;
    
    if (isCreate) {
      return session.copyWith(
        createdByUserId: staff.id,
        createdByName: staff.name,
      );
    } else {
      return session.copyWith(
        updatedByUserId: staff.id,
        updatedByName: staff.name,
      );
    }
  }"""
  
    # 1. Insert _enrichWithStaff after the getters
    if "_enrichWithStaff" not in content:
        content = content.replace("CollectionReference get _gamesRef =>\n      _db.collection(FirebaseConstants.gamesCollection);", "CollectionReference get _gamesRef =>\n      _db.collection(FirebaseConstants.gamesCollection);\n\n" + enrich_game_session)

    # 2. Update startGame
    old_start = """  Future<GameSession> startGame(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.startGame')) return session;
    final docRef = _gamesRef.doc(session.id);
    final batch = _db.batch();
    batch.set(docRef, session.toMap());"""
    
    new_start = """  Future<GameSession> startGame(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.startGame')) return session;
    final enrichedSession = _enrichWithStaff(session, true);
    final docRef = _gamesRef.doc(enrichedSession.id);
    final batch = _db.batch();
    batch.set(docRef, enrichedSession.toMap());"""
    content = content.replace(old_start, new_start)
    
    # 3. Update endGame
    old_end = """  Future<void> endGame(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.endGame')) return;
    final docRef = _gamesRef.doc(session.id);
    final batch = _db.batch();
    batch.set(docRef, session.toMap());"""
    
    new_end = """  Future<void> endGame(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.endGame')) return;
    final enrichedSession = _enrichWithStaff(session, false);
    final docRef = _gamesRef.doc(enrichedSession.id);
    final batch = _db.batch();
    batch.set(docRef, enrichedSession.toMap());"""
    content = content.replace(old_end, new_end)
    
    # 4. Update editCompletedGame
    old_edit = """  Future<void> editCompletedGame({
    required GameSession newSession,
    required GameSession oldSession,
    required List<AuditLog> newLogs,
    required String employeeId,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.editCompletedGame')) return;
    final batch = _db.batch();
    final docRef = _gamesRef.doc(newSession.id);
    
    // Add logs to session
    final updatedSession = newSession.copyWith(
      auditLogs: [...newSession.auditLogs, ...newLogs],
    );

    batch.set(docRef, updatedSession.toMap());"""
    
    new_edit = """  Future<void> editCompletedGame({
    required GameSession newSession,
    required GameSession oldSession,
    required List<AuditLog> newLogs,
    required String employeeId,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.editCompletedGame')) return;
    final batch = _db.batch();
    final docRef = _gamesRef.doc(newSession.id);
    
    // Add logs to session
    GameSession updatedSession = newSession.copyWith(
      auditLogs: [...newSession.auditLogs, ...newLogs],
    );
    updatedSession = _enrichWithStaff(updatedSession, false);

    batch.set(docRef, updatedSession.toMap());"""
    content = content.replace(old_edit, new_edit)
    
    # 5. Fix editCompletedGame call for old names logic
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    inject_identity()
