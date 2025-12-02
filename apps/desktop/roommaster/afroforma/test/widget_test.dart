import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afroforma/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const FormationManagementApp(initialScreen: const Text('Test'))); // Provide a simple Text widget
    expect(find.byType(FormationManagementApp), findsOneWidget);
  });
}