import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/add_note.dart';

/// Repository palsu yang mencatat pemanggilan, sehingga test bisa membuktikan
/// bahwa judul tidak valid **tidak pernah** menyentuh database.
class SpyNoteRepository implements NoteRepository {
  SpyNoteRepository({this.failure});

  Failure? failure;
  int addNoteCalls = 0;
  String? lastTitle;
  String? lastBody;

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addNoteCalls++;
    lastTitle = title;
    lastBody = body;
    if (failure != null) return (note: null, failure: failure);
    return (
      note: Note(
        id: addNoteCalls,
        title: title,
        body: body,
        updatedAt: DateTime(2026, 11, 18),
        dirty: true,
      ),
      failure: null,
    );
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() {
    throw UnimplementedError();
  }

  @override
  Future<({Note? note, Failure? failure})> fetchNoteById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<({bool ok, Failure? failure})> deleteNote(int id) {
    throw UnimplementedError();
  }

  @override
  Future<({int count, Failure? failure})> countDirty() {
    throw UnimplementedError();
  }

  @override
  Future<({bool ok, Failure? failure})> markAllSynced() {
    throw UnimplementedError();
  }
}

void main() {
  test('AddNote menolak judul kosong tanpa memanggil repository', () async {
    final repo = SpyNoteRepository();
    final result = await AddNote(repo).call(title: '');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.failure!.message, AddNote.emptyTitleMessage);
    expect(result.note, isNull);
    expect(repo.addNoteCalls, 0);
  });

  test('AddNote menolak judul berisi spasi saja', () async {
    final repo = SpyNoteRepository();
    final result = await AddNote(repo).call(title: '   ');

    expect(result.failure, isA<ValidationFailure>());
    expect(repo.addNoteCalls, 0);
  });

  test('AddNote merapikan judul dan body sebelum disimpan', () async {
    final repo = SpyNoteRepository();
    final result = await AddNote(repo)
        .call(title: '  Belanja mingguan  ', body: '  susu, telur  ');

    expect(result.failure, isNull);
    expect(result.note, isNotNull);
    expect(repo.addNoteCalls, 1);
    expect(repo.lastTitle, 'Belanja mingguan');
    expect(repo.lastBody, 'susu, telur');
    expect(result.note!.title, 'Belanja mingguan');
  });

  test('AddNote meneruskan kegagalan database tanpa melempar', () async {
    final repo = SpyNoteRepository(
      failure: const LocalFailure('Gagal menyimpan catatan (simulasi)'),
    );
    final result = await AddNote(repo).call(title: 'Catatan valid');

    expect(result.failure, isA<LocalFailure>());
    expect(result.note, isNull);
    expect(repo.addNoteCalls, 1);
  });
}
