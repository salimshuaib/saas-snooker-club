import 'package:cloud_firestore/cloud_firestore.dart';

void logToFirestore(String message) {
  FirebaseFirestore.instance.collection('debug_logs').add({
    'timestamp': FieldValue.serverTimestamp(),
    'message': message,
  });
}
