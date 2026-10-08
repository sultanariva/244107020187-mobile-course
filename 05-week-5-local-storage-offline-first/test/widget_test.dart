import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/pages/settings_page.dart';

void main() {
  testWidgets('Settings page menampilkan toggle mode gelap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mode gelap'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
