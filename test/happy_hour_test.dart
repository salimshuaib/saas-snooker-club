import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/happy_hour/domain/models/happy_hour_offer.dart';

void main() {
  group('HappyHourOffer Time & Eligibility Tests', () {
    final offer = HappyHourOffer(
      id: 'offer_1',
      name: 'Afternoon Deal',
      code: 'AFTN99',
      isActive: true,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
      dailyStartTime: '14:00',
      dailyEndTime: '18:00',
      isOvernightSchedule: false,
      gameOffers: {
        'table_pool_1': 99.0,
        'table_snooker_1': 149.0,
      },
      createdAt: DateTime(2026, 10, 1),
      createdByUserId: 'admin_1',
      createdByName: 'Admin',
    );

    test('Eligible when within date and time window', () {
      final validTime = DateTime(2026, 10, 15, 15, 30); // 15:30 on Oct 15
      expect(offer.isTimeEligible(validTime), isTrue);
      expect(offer.isCurrentlyEligible(validTime, 'table_pool_1'), isTrue);
    });

    test('Ineligible when outside daily time window', () {
      final tooEarly = DateTime(2026, 10, 15, 13, 59); // 13:59
      final tooLate = DateTime(2026, 10, 15, 18, 01); // 18:01
      expect(offer.isTimeEligible(tooEarly), isFalse);
      expect(offer.isTimeEligible(tooLate), isFalse);
    });

    test('Ineligible when outside date boundaries', () {
      final beforeDate = DateTime(2026, 9, 30, 15, 00);
      final afterDate = DateTime(2026, 11, 1, 15, 00);
      expect(offer.isTimeEligible(beforeDate), isFalse);
      expect(offer.isTimeEligible(afterDate), isFalse);
    });

    test('Ineligible if table is not configured in offer', () {
      final validTime = DateTime(2026, 10, 15, 16, 00);
      expect(offer.isCurrentlyEligible(validTime, 'table_ps5_1'), isFalse);
    });

    test('Ineligible if isActive is toggled to false', () {
      final inactiveOffer = offer.copyWith(isActive: false);
      final validTime = DateTime(2026, 10, 15, 16, 00);
      expect(inactiveOffer.isTimeEligible(validTime), isFalse);
      expect(inactiveOffer.isCurrentlyEligible(validTime, 'table_pool_1'), isFalse);
    });
  });

  group('HappyHourOffer Overnight Schedule Tests', () {
    final overnightOffer = HappyHourOffer(
      id: 'offer_night',
      name: 'Midnight Madness',
      code: 'NIGHT79',
      isActive: true,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
      dailyStartTime: '22:00',
      dailyEndTime: '02:00',
      isOvernightSchedule: true,
      gameOffers: {
        'table_pool_1': 79.0,
      },
      createdAt: DateTime(2026, 10, 1),
      createdByUserId: 'admin_1',
      createdByName: 'Admin',
    );

    test('Eligible before midnight (e.g. 23:15)', () {
      final nightTime = DateTime(2026, 10, 12, 23, 15);
      expect(overnightOffer.isTimeEligible(nightTime), isTrue);
    });

    test('Eligible after midnight before end time (e.g. 01:45)', () {
      final earlyMorning = DateTime(2026, 10, 12, 1, 45);
      expect(overnightOffer.isTimeEligible(earlyMorning), isTrue);
    });

    test('Ineligible after end time in morning (e.g. 03:00)', () {
      final lateMorning = DateTime(2026, 10, 12, 3, 00);
      expect(overnightOffer.isTimeEligible(lateMorning), isFalse);
    });

    test('Ineligible during the afternoon (e.g. 15:00)', () {
      final afternoon = DateTime(2026, 10, 12, 15, 00);
      expect(overnightOffer.isTimeEligible(afternoon), isFalse);
    });
  });
}
