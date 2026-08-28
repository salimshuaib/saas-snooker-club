import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snooker_club/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build app wrapped in ProviderScope
    await tester.pumpWidget(const ProviderScope(child: SnookerClubApp()));
    // Verify the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
