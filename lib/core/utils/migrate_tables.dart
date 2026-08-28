import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

Future<void> migrateTablesPricing(String clubId) async {
  try {
    final clubDoc = await FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .get();
    if (!clubDoc.exists) {
      debugPrint('Club not found');
      return;
    }

    final settingsDoc = await clubDoc.reference
        .collection('settings')
        .doc('app_settings')
        .get();
    PricingSettings globalPricing = const PricingSettings();
    if (settingsDoc.exists) {
      final appSettingsMap = settingsDoc.data()!;
      if (appSettingsMap['pricing'] != null) {
        globalPricing = PricingSettings.fromMap(
          appSettingsMap['pricing'] as Map<String, dynamic>,
        );
      }
    }

    final tablesRef = clubDoc.reference.collection('tables');
    final tablesSnapshot = await tablesRef.get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in tablesSnapshot.docs) {
      final map = doc.data();
      if (map['pricing'] == null || (map['pricing'] as Map).isEmpty) {
        // Find the table type
        final typeStr = map['type'] as String?;
        final type = TableType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => TableType.snooker,
        );

        Map<String, double> pricing = {};

        if (type == TableType.snooker) {
          pricing = {
            'perMinute': globalPricing.snookerPerMinute,
            'halfHour': globalPricing.snookerHalfHour,
            'oneHour': globalPricing.snookerOneHour,
            'racePerMinute': globalPricing.snookerRacePerMinute,
            'rummyPerMinute': globalPricing.snookerRummyPerMinute,
          };
        } else if (type == TableType.indianPool) {
          pricing = {
            'perFrame': globalPricing.indianPoolPerFrame,
            'perMinute': globalPricing.indianPoolPerMinute,
            'halfHour': globalPricing.indianPoolHalfHour,
            'oneHour': globalPricing.indianPoolOneHour,
            'racePerMinute': globalPricing.indianPoolRacePerMinute,
          };
        } else if (type == TableType.americanPool) {
          pricing = {
            'perFrame': globalPricing.americanPoolPerFrame,
            'perMinute': globalPricing.americanPoolPerMinute,
            'halfHour': globalPricing.americanPoolHalfHour,
            'oneHour': globalPricing.americanPoolOneHour,
            'racePerMinute': globalPricing.americanPoolRacePerMinute,
          };
        }

        batch.update(doc.reference, {'pricing': pricing});
        debugPrint('Migrating table: ${doc.id} with type: ${type.name}');
      }
    }

    await batch.commit();
    debugPrint('Migration complete');
  } catch (e) {
    debugPrint('Migration failed: $e');
  }
}
