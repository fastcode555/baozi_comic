import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baozi_comic/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BaoziComicApp());

    // Wait for the widget tree to settle
    await tester.pumpAndSettle();

    // Verify that the app starts without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}