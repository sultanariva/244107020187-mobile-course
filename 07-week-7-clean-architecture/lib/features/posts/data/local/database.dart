import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Pembuka database cache untuk fitur posts (tabel `cached_posts`).
///
/// Berada di layer `data` fitur posts agar `core` tetap steril dari framework.
Future<Database> openPostsDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'posts_cache.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    },
  );
}
