import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke — pump empty MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('PEPS')),
        ),
      ),
    );
    expect(find.text('PEPS'), findsOneWidget);
  });
}
