import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_the_object/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const GuessTheObjectApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
