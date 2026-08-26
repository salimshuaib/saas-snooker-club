import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/utils/logger.dart';

/// Firestore service with offline persistence enabled.
/// All Firestore operations in the app should go through this service.
class FirestoreService {
  late final FirebaseFirestore _db;

  FirestoreService() {
    _db = FirebaseFirestore.instance;
  }

  /// Call this once at app startup to enable offline persistence.
  Future<void> initialize() async {
    try {
      // Enable offline persistence so data is available without internet.
      // Changes made offline are queued and synced when connection resumes.
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      AppLogger.info('Firestore initialized with offline persistence enabled');
    } catch (e) {
      AppLogger.error('Firestore initialization error: $e');
    }
  }

  /// The Firestore instance — use this in repositories.
  FirebaseFirestore get db => _db;

  /// Helper to get a club document reference
  DocumentReference clubDoc(String clubId) {
    return _db.collection('clubs').doc(clubId);
  }

  /// Quick connectivity test: tries to write a test document.
  /// Returns true if Firestore is reachable.
  Future<bool> testConnection() async {
    try {
      await _db
          .collection('_connection_test')
          .doc('ping')
          .set({'timestamp': FieldValue.serverTimestamp()});
      AppLogger.info('Firestore connection test: SUCCESS');
      return true;
    } catch (e) {
      AppLogger.error('Firestore connection test failed: $e');
      return false;
    }
  }
}
