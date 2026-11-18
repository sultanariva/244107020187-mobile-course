import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Pembuka database untuk fitur notes (tabel `notes`).
///
/// Berada di layer `data` fitur notes agar `core` tetap steril dari framework
/// (dependency rule: hanya `data` yang boleh tahu SQLite).
Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
}
