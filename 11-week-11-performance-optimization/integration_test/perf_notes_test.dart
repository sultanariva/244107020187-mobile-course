import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:week5_offline_notes/features/notes/data/local/database.dart';
import 'package:week5_offline_notes/features/notes/presentation/widgets/note_tile.dart';
import 'package:week5_offline_notes/main.dart' as app;

/// Skenario pengukuran performa Minggu 11.
///
/// Dipakai dua kali dengan isi kode yang sama: sebelum optimasi (baseline) dan
/// sesudah optimasi, supaya perbandingannya adil.
///
/// Jalankan:
///   flutter drive --profile -d emulator-5554 \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/perf_notes_test.dart
const int seedCount = 200;

Future<void> _seedNotes() async {
  final db = await openNotesDb();
  final existing =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM notes')) ??
      0;
  if (existing >= seedCount) {
    await db.close();
    return;
  }

  final base = DateTime(2026, 11, 23, 8);
  final batch = db.batch();
  for (var i = existing; i < seedCount; i++) {
    batch.insert('notes', {
      'title': 'Catatan uji ${i + 1}',
      'body': 'Isi catatan uji nomor ${i + 1} untuk pengukuran scroll.',
      'updated_at': base.subtract(Duration(minutes: i)).toIso8601String(),
      'dirty': i % 3 == 0 ? 1 : 0,
    });
  }
  await batch.commit(noResult: true);
  await db.close();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profil: scroll daftar catatan, buka detail, kembali', (
    tester,
  ) async {
    await _seedNotes();
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(NoteTile), findsWidgets);

    await binding.watchPerformance(() async {
      for (var round = 0; round < 2; round++) {
        // Scroll cepat tiga kali, seperti skenario codelab.
        for (var i = 0; i < 3; i++) {
          await tester.fling(
            find.byType(NoteTile).first,
            const Offset(0, -700),
            3000,
          );
          await tester.pumpAndSettle();
        }

        // Buka detail lalu kembali.
        await tester.tap(find.byType(NoteTile).first);
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }, reportKey: 'notes_scroll');
  });
}
