import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento/src/app/app.dart';

void main() {
  testWidgets('App launches and settles', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: App()));

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);

    // Pump for enough time for the splash screen timer to fire
    // Use multiple pumps to avoid the "too many" scaffold issue
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));

    // Just verify the app didn't crash
    expect(tester.takeException(), isNull);
  });
}
