import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:snooker_club/core/utils/logger.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> setup() async {
    try {
      bool isSupported = true;
      if (kIsWeb) {
        isSupported = await _fcm.isSupported();
      }

      if (!isSupported) {
        AppLogger.info('Push notifications are not supported in this browser context.');
        return;
      }

      // 2. Local Notifications Setup for foreground display (Native only)
      if (!kIsWeb) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );
        await _localNotifications.initialize(settings: initializationSettings);

        // Create a high importance channel for Android
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // 3. Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('Received foreground message: ${message.messageId}');
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null && !kIsWeb) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      // 4. Save Token whenever user logs in or app starts IF permission is already granted
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          NotificationSettings settings = await _fcm.getNotificationSettings();
          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            await _saveTokenToDatabase(user.uid);
          }
        }
      });

      // 5. Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _updateTokenInDatabase(user.uid, newToken);
        }
      });
    } catch (e) {
      AppLogger.error('Failed to setup push notification listeners: $e');
    }
  }

  /// Request permission explicitly from the user (e.g. after login or button press)
  Future<bool> requestPermission() async {
    try {
      bool isSupported = true;
      if (kIsWeb) {
        isSupported = await _fcm.isSupported();
      }

      if (!isSupported) {
        AppLogger.info('Push notifications not supported on this browser context.');
        return false;
      }

      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      AppLogger.info('User granted permission: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
         final user = FirebaseAuth.instance.currentUser;
         if (user != null) {
           await _saveTokenToDatabase(user.uid);
         }
         return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<void> _saveTokenToDatabase(String uid) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenInDatabase(uid, token);
      }
    } catch (e) {
      AppLogger.error('Error getting FCM token: $e');
    }
  }

  Future<void> _updateTokenInDatabase(String uid, String token) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    AppLogger.info('Saved FCM token to database for user: $uid');
  }

  Future<void> removeToken(String uid) async {
    try {
      bool isSupported = true;
      if (kIsWeb) {
        isSupported = await _fcm.isSupported();
      }
      
      if (!isSupported) return;

      String? token = await _fcm.getToken();
      if (token != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        await userRef.set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
        AppLogger.info('Removed FCM token from database for user: $uid');
      }
    } catch (e) {
      AppLogger.error('Error removing FCM token: $e');
    }
  }
}
