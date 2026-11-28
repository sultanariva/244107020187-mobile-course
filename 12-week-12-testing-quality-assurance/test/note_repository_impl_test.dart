import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/data/repositories/note_repository_impl.dart';

/// Skema yang sama dengan `lib/features/notes/data/local/database.dart`,
/// dibuat ulang di database in-memory agar implementasi SQLite benar-benar
/// dieksekusi tanpa menyentuh file perangkat.
const String _createNotes = '''
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
)''';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late NoteRepositoryImpl repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(_createNotes);
    repository = NoteRepositoryImpl(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('NoteRepositoryImpl dengan SQLite in-memory', () {
    test(
      'addNote menyimpan baris dirty dan fetchNotes mengembalikannya',
      () async {
        final added = await repository.addNote(
          title: 'Belanja mingguan',
          body: 'susu, telur',
        );

        expect(added.failure, isNull);
        expect(added.note, isNotNull);
        expect(added.note!.id, isNotNull);
        expect(added.note!.dirty, isTrue);

        final result = await repository.fetchNotes();
        expect(result.failure, isNull);
        expect(result.notes, hasLength(1));
        expect(result.notes.single.title, 'Belanja mingguan');
        expect(result.notes.single.body, 'susu, telur');
      },
    );

    test('fetchNotes mengurutkan updated_at terbaru lebih dulu', () async {
      await db.insert('notes', {
        'title': 'Lama',
        'body': '',
        'updated_at': '2026-11-01T08:00:00.000',
        'dirty': 0,
      });
      await db.insert('notes', {
        'title': 'Baru',
        'body': '',
        'updated_at': '2026-11-20T08:00:00.000',
        'dirty': 0,
      });

      final result = await repository.fetchNotes();

      expect(result.notes.map((n) => n.title), ['Baru', 'Lama']);
    });

    test('fetchNoteById mengembalikan catatan atau null tanpa error', () async {
      final added = await repository.addNote(title: 'Detail');

      final found = await repository.fetchNoteById(added.note!.id!);
      expect(found.failure, isNull);
      expect(found.note!.title, 'Detail');

      final missing = await repository.fetchNoteById(9999);
      expect(missing.failure, isNull);
      expect(missing.note, isNull);
    });

    test('deleteNote menghapus baris dan melaporkan ok', () async {
      final added = await repository.addNote(title: 'Akan dihapus');

      final deleted = await repository.deleteNote(added.note!.id!);
      expect(deleted.ok, isTrue);
      expect(deleted.failure, isNull);

      final result = await repository.fetchNotes();
      expect(result.notes, isEmpty);
    });

    test('countDirty lalu markAllSynced membersihkan antrean', () async {
      await repository.addNote(title: 'Satu');
      await repository.addNote(title: 'Dua');

      final before = await repository.countDirty();
      expect(before.count, 2);

      final marked = await repository.markAllSynced();
      expect(marked.ok, isTrue);

      final after = await repository.countDirty();
      expect(after.count, 0);
    });

    test('kegagalan database menjadi LocalFailure, bukan exception', () async {
      final broken = NoteRepositoryImpl(
        () async => throw StateError('database ditutup'),
      );

      final result = await broken.fetchNotes();

      expect(result.failure, isA<LocalFailure>());
      expect(result.notes, isEmpty);
      expect(result.failure!.message, contains('Gagal membaca catatan'));
    });
  });
}
