import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/data/models/note_model.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

/// Repository palsu yang mengimplementasikan interface domain (bukan extends
/// impl SQLite), sehingga tidak pernah menyentuh database sungguhan.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false});

  final List<Note> items;
  final bool throwError;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (throwError) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (notes: items, failure: null);
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    return (count: items.where((n) => n.dirty).length, failure: null);
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

  @override
  Future<({bool ok, Failure? failure})> markAllSynced() {
    throw UnimplementedError();
  }
}

void main() {
  test('NoteModel.fromMap aman terhadap field yang hilang', () {
    final note = NoteModel.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
  });

  test('flag dirty bertahan pada serialisasi model', () {
    final model = NoteModel(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = NoteModel.fromMap(model.toMap());
    expect(restored.dirty, isTrue);
  });

  test('NoteModel.toEntity menghasilkan entity murni', () {
    final entity = NoteModel(
      id: 3,
      title: 'Judul',
      updatedAt: DateTime(2026, 9, 18),
    ).toEntity();
    expect(entity, isA<Note>());
    expect(entity.id, 3);
    expect(entity.title, 'Judul');
  });

  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(items: [
            Note(title: 'Tes', updatedAt: DateTime.now()),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notes = await container.read(notesProvider.future);
    expect(notes.length, 1);
    expect(notes.first.title, 'Tes');
  });

  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(notesProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
