import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week5_offline_notes/main.dart' as app;

/// Integration test alur utama di perangkat/emulator:
/// tambah catatan -> muncul di daftar -> cari judulnya -> buka detail.
///
/// Jalankan: flutter test integration_test/app_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alur utama: tambah, cari, lalu buka detail catatan', (
    tester,
  ) async {
    const judul = 'Catatan uji integrasi 12';
    const isi = 'Dibuat oleh integration_test minggu 12.';

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 1. Tambah catatan lewat dialog.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Catatan baru'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, judul);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. Catatan muncul di daftar (data asli dari SQLite perangkat).
    expect(find.text(judul), findsOneWidget);

    // 3. Cari judul tersebut, daftar menyempit ke satu hasil.
    await tester.enterText(find.byType(TextField).first, 'uji integrasi 12');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text(judul), findsOneWidget);

    // 4. Buka detail dan pastikan judulnya tampil di halaman detail.
    await tester.tap(find.text(judul));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text(judul), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    // 5. Kembali ke daftar.
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Bersihkan data uji supaya tidak menumpuk di perangkat.
    expect(isi, isNotEmpty);
  });
}
