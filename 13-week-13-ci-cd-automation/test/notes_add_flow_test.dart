import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/add_note.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/notes_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

/// Repository palsu di memori: cukup untuk menguji alur UI tanpa SQLite.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note>? initial}) : _notes = [...?initial];

  final List<Note> _notes;
  int _nextId = 100;
  int addCalls = 0;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    final sorted = [..._notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return (notes: sorted, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> fetchNoteById(int id) async {
    final match = _notes.where((n) => n.id == id);
    return (note: match.isEmpty ? null : match.first, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCalls++;
    final note = Note(
      id: _nextId++,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    _notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<({bool ok, Failure? failure})> deleteNote(int id) async {
    _notes.removeWhere((n) => n.id == id);
    return (ok: true, failure: null);
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    return (count: _notes.where((n) => n.dirty).length, failure: null);
  }

  @override
  Future<({bool ok, Failure? failure})> markAllSynced() async {
    return (ok: true, failure: null);
  }
}

Widget _app(FakeNoteRepository repository) {
  return ProviderScope(
    overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: NotesPage()),
  );
}

void main() {
  group('Halaman Catatan (widget)', () {
    testWidgets('menampilkan catatan yang sudah ada', (tester) async {
      final repository = FakeNoteRepository(
        initial: [
          Note(
            id: 1,
            title: 'Catatan pertama',
            body: 'isi',
            updatedAt: DateTime(2026, 11, 1),
          ),
          Note(
            id: 2,
            title: 'Catatan kedua',
            body: 'isi',
            updatedAt: DateTime(2026, 11, 2),
          ),
        ],
      );

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.text('Catatan pertama'), findsOneWidget);
      expect(find.text('Catatan kedua'), findsOneWidget);
      expect(find.text('Belum ada catatan'), findsNothing);
    });

    testWidgets('judul kosong ditolak dan tidak menambah data', (tester) async {
      final repository = FakeNoteRepository();

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text(AddNote.emptyTitleMessage), findsOneWidget);
      expect(repository.addCalls, 0);
      expect(find.text('Belum ada catatan'), findsOneWidget);
    });

    testWidgets('judul valid menambah catatan dan muncul di daftar', (
      tester,
    ) async {
      final repository = FakeNoteRepository();

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        '  Belanja mingguan  ',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(repository.addCalls, 1);
      // Judul dirapikan oleh use case sebelum disimpan.
      expect(find.text('Belanja mingguan'), findsOneWidget);
    });
  });
}
