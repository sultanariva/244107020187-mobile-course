import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:week5_offline_notes/features/notes/data/local/database.dart';

/// Menyiapkan data uji performa: 200 catatan di database aplikasi.
///
/// Dijalankan sekali dalam mode debug sebelum pengukuran profile:
///   flutter test integration_test/seed_notes_test.dart -d emulator-5554
///
/// Tidak memakai `watchPerformance`, sehingga tidak memerlukan koneksi VM
/// Service (yang gagal di emulator ini).
const int seedTarget = 200;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seed catatan uji untuk pengukuran performa', (tester) async {
    final db = await openNotesDb();
    final existing =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM notes'),
        ) ??
        0;

    if (existing < seedTarget) {
      final base = DateTime(2026, 11, 23, 8);
      final batch = db.batch();
      for (var i = existing; i < seedTarget; i++) {
        batch.insert('notes', {
          'title': 'Catatan uji ${i + 1}',
          'body': 'Isi catatan uji nomor ${i + 1} untuk pengukuran scroll.',
          'updated_at': base.subtract(Duration(minutes: i)).toIso8601String(),
          'dirty': i % 3 == 0 ? 1 : 0,
        });
      }
      await batch.commit(noResult: true);
    }

    final total =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM notes'),
        ) ??
        0;
    await db.close();

    expect(total, greaterThanOrEqualTo(seedTarget));
  });
}
