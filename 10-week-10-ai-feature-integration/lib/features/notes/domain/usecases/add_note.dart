import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case: menambah catatan sekaligus menegakkan aturan bisnis judul.
///
/// Aturan "judul wajib diisi" diletakkan di domain, bukan di widget, supaya
/// aturan yang sama dipakai UI, test, dan pemanggil lain. Judul dirapikan
/// (trim) sebelum disimpan sehingga judul berisi spasi saja ikut ditolak.
class AddNote {
  const AddNote(this._repository);

  final NoteRepository _repository;

  /// Pesan yang sama dipakai UI dan test, jadi tidak bisa berbeda diam-diam.
  static const String emptyTitleMessage = 'Judul catatan tidak boleh kosong';

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return Future.value((
        note: null,
        failure: const ValidationFailure(emptyTitleMessage),
      ));
    }
    return _repository.addNote(title: cleanTitle, body: body.trim());
  }
}
