// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget fields meet your
// expectations.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A lightweight smoke test that verifies MaterialApp renders without crashing.
// Full integration tests require a Firebase test project.
void main() {
  testWidgets('MaterialApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('ShopShare'),
          ),
        ),
      ),
    );

    expect(find.text('ShopShare'), findsOneWidget);
  });
}