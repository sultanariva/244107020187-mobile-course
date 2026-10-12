import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case: satu operasi bisnis "ambil semua catatan".
class GetNotes {
  const GetNotes(this._repository);

  final NoteRepository _repository;

  Future<({List<Note> notes, Failure? failure})> call() {
    return _repository.fetchNotes();
  }
}
