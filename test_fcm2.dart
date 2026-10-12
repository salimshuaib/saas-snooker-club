import 'package:firebase_messaging/firebase_messaging.dart'; void main() async { NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings(); }
