import '../../../../core/failures.dart';
import '../entities/note.dart';

/// Kontrak yang dibutuhkan domain. Implementasi konkret hidup di layer `data`.
///
/// Setiap operasi mengembalikan *record* Dart `({data, failure})` agar
/// sukses/gagal eksplisit dan exception tidak bocor ke presentation.
abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();

  Future<({Note? note, Failure? failure})> fetchNoteById(int id);

  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });

  Future<({bool ok, Failure? failure})> deleteNote(int id);

  Future<({int count, Failure? failure})> countDirty();

  Future<({bool ok, Failure? failure})> markAllSynced();
}
