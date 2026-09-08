import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  
  print("=== STARTING AUDIT ===");
  final clubsSnap = await db.collection('clubs').get();
  
  String? snookerHubId;
  for (var doc in clubsSnap.docs) {
    final data = doc.data();
    final name = data['name'] ?? data['clubName'] ?? data['businessName'] ?? '';
    print("Found club: ${doc.id} - $name");
    if (name.toString().toLowerCase().contains('snooker hub')) {
      snookerHubId = doc.id;
    }
  }
  
  if (snookerHubId == null) {
    print("Could not find Snooker Hub club!");
    return;
  }
  
  print("Found Snooker Hub with ID: $snookerHubId");
  
  // Now fetch games
  final gamesSnap = await db.collection('clubs').doc(snookerHubId).collection('games').get();
  print("Fetched ${gamesSnap.docs.length} games.");
  
  // Fetch quick sales
  final qsSnap = await db.collection('clubs').doc(snookerHubId).collection('quick_sales').get();
  print("Fetched ${qsSnap.docs.length} quick sales.");

  // Fetch payments
  final paymentsSnap = await db.collection('clubs').doc(snookerHubId).collection('payment_history').get();
  print("Fetched ${paymentsSnap.docs.length} payment history records.");

  // Fetch credit profiles (customers)
  final creditSnap = await db.collection('clubs').doc(snookerHubId).collection('credit_profiles').get();
  print("Fetched ${creditSnap.docs.length} credit profiles.");

  double totalGameBill = 0;
  double totalGameDiscount = 0;
  
  for (var doc in gamesSnap.docs) {
    final data = doc.data();
    // Assuming 'status': 'completed' and maybe has billing breakdown
    final status = data['status'];
    if (status == 'completed' || status == 'billing') {
      final breakdown = data['chargeBreakdown'];
      if (breakdown != null) {
        totalGameBill += (breakdown['finalAmount'] ?? 0.0);
        totalGameDiscount += (breakdown['totalDiscount'] ?? 0.0);
      }
    }
  }
  
  print("Total Game Bill (finalAmount): $totalGameBill");
  print("Total Game Discount: $totalGameDiscount");
  
  double totalOutstanding = 0;
  for (var doc in creditSnap.docs) {
    final data = doc.data();
    totalOutstanding += (data['outstandingBalance'] ?? 0.0);
  }
  
  print("Total Outstanding Balance in DB: $totalOutstanding");
  
  print("=== AUDIT COMPLETE ===");
}
