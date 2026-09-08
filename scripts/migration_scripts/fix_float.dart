import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/features/credit/data/credit_repository.dart';

// Since we are running outside of the regular flutter start, we just initialize and go.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnvironment.initialize();
  await Firebase.initializeApp(
    options: AppEnvironment.firebaseOptions,
  );

  final db = FirebaseFirestore.instance;
  // This is the production club ID based on the python script.
  final clubId = 'gX2ll3aNnBZKXyMYoIuB'; 
  
  print('Starting floating point cleanup for club: $clubId');

  final creditRepo = CreditRepository(db, clubId: clubId);
  final creditsSnap = await db.collection('clubs').doc(clubId).collection('credits').get();

  print('Found ${creditsSnap.docs.length} customers. Recalculating all...');

  for (final doc in creditsSnap.docs) {
    try {
      await creditRepo.recalculateCustomerAccount(doc.id);
    } catch (e) {
      print('Failed to recalculate ${doc.id}: $e');
    }
  }

  print('Done!');
}
