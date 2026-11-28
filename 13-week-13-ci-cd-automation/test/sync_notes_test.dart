import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/sync_notes.dart';

/// Repository palsu yang bisa mengatur hasil `countDirty` dan `markAllSynced`.
class FakeSyncRepository implements NoteRepository {
  FakeSyncRepository({
    this.dirtyCount = 0,
    this.countFailure,
    this.markFailure,
  });

  final int dirtyCount;
  final Failure? countFailure;
  final Failure? markFailure;
  int markCalls = 0;

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    return (count: dirtyCount, failure: countFailure);
  }

  @override
  Future<({bool ok, Failure? failure})> markAllSynced() async {
    markCalls++;
    return (ok: markFailure == null, failure: markFailure);
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
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<({bool ok, Failure? failure})> deleteNote(int id) {
    throw UnimplementedError();
  }
}

void main() {
  group('SyncNotes', () {
    test('tanpa catatan kotor tidak memanggil markAllSynced', () async {
      final repository = FakeSyncRepository(dirtyCount: 0);

      final result = await SyncNotes(repository).call();

      expect(result.synced, 0);
      expect(result.failure, isNull);
      expect(repository.markCalls, 0);
    });

    test('menghitung antrean lalu menandai semua tersinkron', () async {
      final repository = FakeSyncRepository(dirtyCount: 3);

      final result = await SyncNotes(repository).call();

      expect(result.synced, 3);
      expect(result.failure, isNull);
      expect(repository.markCalls, 1);
    });

    test('kegagalan membaca antrean diteruskan apa adanya', () async {
      final repository = FakeSyncRepository(
        countFailure: const LocalFailure('db terkunci'),
      );

      final result = await SyncNotes(repository).call();

      expect(result.synced, 0);
      expect(result.failure, isA<LocalFailure>());
      expect(repository.markCalls, 0);
    });

    test('kegagalan menandai bersih tidak dilaporkan sebagai sukses', () async {
      final repository = FakeSyncRepository(
        dirtyCount: 2,
        markFailure: const LocalFailure('gagal update'),
      );

      final result = await SyncNotes(repository).call();

      expect(result.synced, 0);
      expect(result.failure, isA<LocalFailure>());
      expect(repository.markCalls, 1);
    });
  });
}
