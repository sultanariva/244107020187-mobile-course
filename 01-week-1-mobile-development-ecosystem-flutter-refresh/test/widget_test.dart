import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/main.dart';

void main() {
  testWidgets('Displays the student profile', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sultan Nashira Ariva'), findsOneWidget);
    expect(find.text('sultannanda55@gmail.com'), findsOneWidget);
    expect(find.text('244107020187'), findsOneWidget);
    expect(find.text('Politeknik Negeri Malang'), findsOneWidget);
    expect(find.text('Pemrograman Mobile — Minggu 1'), findsOneWidget);
    expect(find.byIcon(Icons.school), findsOneWidget);
  });
}