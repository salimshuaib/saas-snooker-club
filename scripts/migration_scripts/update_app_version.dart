import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:snooker_club/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;

  print('Updating app config to 1.0.4...');

  await db.collection('settings').doc('app_config').set({
    'minimum_required_version': '1.0.4',
    'latest_version': '1.0.4',
    'force_update': true,
    'update_message':
        'A critical update is required. Please download the latest version to continue using the app.',
  }, SetOptions(merge: true));

  print('App config updated successfully!');
}
