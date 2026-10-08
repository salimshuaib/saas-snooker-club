import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/core/utils/billing_utils.dart';

void main() {
  group('BillingUtils', () {
    test('generateFinalAmountOptions returns exact options', () {
      final options1 = BillingUtils.generateFinalAmountOptions(24.0, incrementPaise: 1000);
      expect(options1, [20.0, 30.0]);

      final options2 = BillingUtils.generateFinalAmountOptions(20.0, incrementPaise: 1000);
      expect(options2, [20.0]);

      final options3 = BillingUtils.generateFinalAmountOptions(25.0, incrementPaise: 1000);
      expect(options3, [20.0, 30.0]);

      final options4 = BillingUtils.generateFinalAmountOptions(2.0, incrementPaise: 1000);
      expect(options4, [0.0, 10.0]);
    });
  });
}
