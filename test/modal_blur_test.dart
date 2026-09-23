import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/core/widgets/modals/app_modal.dart';

void main() {
  testWidgets('AppModal.showDialog adds a blurred backdrop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppModal.showDialog(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text('Test'),
                        content: Text('Content'),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
  });
}
