import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

/// Use case: sinkronisasi catatan kotor (dirty) ke server.
///
/// Punya logika nyata (menghitung antrean, menunggu upload, menandai bersih),
/// sehingga layak menjadi use case. Server disimulasikan dengan delay; pada
/// project nyata, kirim tiap catatan dirty ke REST API lalu tandai bersih
/// saat 2xx.
class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  Future<({int synced, Failure? failure})> call() async {
    final countResult = await _repository.countDirty();
    if (countResult.failure != null) {
      return (synced: 0, failure: countResult.failure);
    }

    final dirtyCount = countResult.count;
    if (dirtyCount == 0) return (synced: 0, failure: null);

    await Future.delayed(const Duration(seconds: 1));

    final markResult = await _repository.markAllSynced();
    if (markResult.failure != null) {
      return (synced: 0, failure: markResult.failure);
    }

    return (synced: dirtyCount, failure: null);
  }
}
