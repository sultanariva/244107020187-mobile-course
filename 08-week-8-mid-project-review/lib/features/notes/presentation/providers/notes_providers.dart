import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';

/// Satu-satunya tempat wiring dependensi (DI) untuk fitur notes.
///
/// Widget tidak pernah `NoteRepositoryImpl()` sendiri; semua lewat provider.

// Data layer: database opener disuntikkan (mudah diganti fake saat test).
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openNotesDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi.
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final syncNotesProvider = Provider<SyncNotes>((ref) {
  return SyncNotes(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI.
final notesProvider = FutureProvider<List<Note>>(
  (ref) async {
    final result = await ref.watch(getNotesProvider).call();
    if (result.failure != null) throw Exception(result.failure!.message);
    return result.notes;
  },
  // Riverpod 3: nonaktifkan retry otomatis agar error langsung final
  // dan mudah diuji tanpa menunggu retry.
  retry: (retryCount, error) => null,
);

final dirtyCountProvider = FutureProvider<int>(
  (ref) async {
    final result = await ref.watch(noteRepositoryProvider).countDirty();
    if (result.failure != null) throw Exception(result.failure!.message);
    return result.count;
  },
  retry: (retryCount, error) => null,
);

final noteDetailProvider = FutureProvider.family<Note?, int>(
  (ref, id) async {
    final result = await ref.watch(noteRepositoryProvider).fetchNoteById(id);
    if (result.failure != null) throw Exception(result.failure!.message);
    return result.note;
  },
  retry: (retryCount, error) => null,
);
