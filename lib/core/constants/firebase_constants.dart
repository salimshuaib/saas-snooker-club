/// Firebase collection names and configuration constants.
/// These will be used when Firebase is connected.
class FirebaseConstants {
  FirebaseConstants._();

  // Collections
  static const String usersCollection = 'users';
  static const String tablesCollection = 'tables';
  static const String gamesCollection = 'games';
  static const String inventoryCollection = 'inventory';
  static const String salesCollection = 'quick_sales';
  static const String creditsCollection = 'credits';
  static const String settingsCollection = 'settings';
  static const String clubsCollection = 'clubs';
  static const String userClubsCollection = 'user_clubs';
  static const String platformCollection = 'platform';

  // Sub-paths
  static const String ordersSubCollection = 'orders';

  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String productImagesPath = 'product_images';
}
