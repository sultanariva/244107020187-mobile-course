# Output Awal AI (Baseline) — Minggu 7

Ringkasan usulan AI **sebelum** diverifikasi. Disimpan apa adanya untuk
dibandingkan dengan keputusan final di `verification_and_decision.md`.

## 1. Struktur yang diusulkan AI

```text
lib/
├── core/
│   └── failures.dart
├── features/
│   └── notes/
│       ├── domain/
│       │   ├── entities/note.dart
│       │   └── repositories/note_repository.dart   # interface + impl di sini
│       ├── data/
│       │   └── models/note_model.dart
│       └── presentation/
│           ├── providers/notes_providers.dart
│           └── pages/notes_page.dart
└── main.dart
```

## 2. Pemetaan file yang diusulkan AI

| File lama | Usulan AI |
| --- | --- |
| `lib/data/local/note.dart` | pindah ke `domain/entities/note.dart` (mapping dibiarkan menempel) |
| `lib/data/repositories/note_repository.dart` | pindah ke `domain/repositories/note_repository.dart`, interface + impl dalam satu file |
| `lib/pages/notes_page.dart` | pindah ke `presentation/pages/` |
| `lib/pages/settings_page.dart` | dibiarkan di `lib/pages/` (fitur kedua menyusul) |
| `lib/data/sync.dart` | dibiarkan di `data/` |

## 3. Use case yang diusulkan AI

AI membuat use case untuk **setiap** operasi, satu file per operasi:

```text
usecases/get_notes.dart
usecases/add_note.dart
usecases/delete_note.dart
usecases/get_note_by_id.dart
usecases/sync_notes.dart
```

## 4. Wiring DI yang diusulkan AI

```dart
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(openDb: openNotesDb); // tipe konkret, bukan abstraksi
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  return ref.watch(noteRepositoryProvider).fetchNotes(); // masih List<Note>, exception bocor
});
```

## 5. Catatan tambahan dari AI

- AI menyatakan "interface dan impl boleh satu file agar ringkas".
- AI menyatakan "use case wajib untuk semua operasi agar konsisten".
- AI menyarankan menambah package `get_it` "agar DI lebih rapi".
- AI tidak menyebut pemisahan entity vs model (mapping tetap di entity).
