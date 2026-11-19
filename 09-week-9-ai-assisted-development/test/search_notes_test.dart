import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/search_notes.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/notes_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

List<Note> _notes() => [
  Note(title: 'Belanja mingguan', updatedAt: DateTime(2026, 11, 1)),
  Note(title: 'belanja bulanan', updatedAt: DateTime(2026, 11, 2)),
  Note(title: 'Ide tulisan', updatedAt: DateTime(2026, 11, 3)),
];

void main() {
  const search = SearchNotes();

  test(
    'kata kunci kosong mengembalikan semua catatan tanpa mengubah urutan',
    () {
      final result = search(_notes(), '   ');
      expect(result, hasLength(3));
      expect(result.first.title, 'Belanja mingguan');
    },
  );

  test('pencarian tidak peduli huruf besar/kecil', () {
    expect(search(_notes(), 'BELANJA'), hasLength(2));
    expect(search(_notes(), 'belanja'), hasLength(2));
  });

  test('spasi di tepi kata kunci diabaikan', () {
    expect(search(_notes(), '  tulisan  '), hasLength(1));
  });

  test('kata kunci tanpa kecocokan mengembalikan daftar kosong', () {
    expect(search(_notes(), 'zzz-tak-ada'), isEmpty);
  });

  testWidgets('empty state membedakan "belum ada catatan" dan "tidak cocok"', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) async => _notes()),
          dirtyCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Kondisi awal: daftar tampil, bukan empty state.
    expect(find.text('Belanja mingguan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada catatan dengan judul "zzz"'), findsOneWidget);
    expect(find.text('Belanja mingguan'), findsNothing);
  });
}
