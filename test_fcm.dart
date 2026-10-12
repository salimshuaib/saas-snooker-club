import 'package:firebase_messaging/firebase_messaging.dart'; void main() async { bool supported = await FirebaseMessaging.instance.isSupported(); }
