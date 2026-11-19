# AI Log — Minggu 9 (AI-Assisted Development)

- **Tanggal**: 18 November 2026
- **Project**: `week5_offline_notes` (feature-first Clean Architecture, hasil Minggu 7-8)
- **AI yang dipakai**: AI coding assistant di sesi praktikum ini (model `cbcn/deepseek-v4.1-flash`)
- **Fitur yang diminta**: pencarian judul catatan + empty state

## 1. Prompt inti (lima slot)

```text
Tambah fitur pencarian judul catatan pada halaman Catatan (NotesPage).

Tujuan: pengguna bisa mengetik kata kunci di kolom cari, daftar langsung
tersaring berdasarkan judul, dan muncul empty state saat tidak ada yang cocok.
Sertakan 1 widget test untuk empty state.

Arsitektur: feature-first Clean Architecture (presentation -> domain <- data).
Aturan filter HARUS berupa use case murni di domain (tanpa Flutter, tanpa
SQLite). Widget tidak boleh memanggil SQLite atau repository untuk menyaring.

Larangan: jangan ubah schema database, jangan pindahkan CRUD yang sudah jalan,
jangan pakai package baru, jangan menyentuh fitur posts dan settings.

Konteks yang ditempel:
- lib/features/notes/domain/entities/note.dart (field: id, title, body, updatedAt, dirty)
- lib/features/notes/domain/usecases/get_notes.dart (gaya use case: class + call())
- lib/features/notes/presentation/providers/notes_providers.dart (Riverpod 3.4.3,
  provider addNoteProvider/getNotesProvider, notesProvider FutureProvider)
- lib/features/notes/presentation/pages/notes_page.dart (ConsumerWidget, AppBar + FAB)
- pubspec.yaml: flutter_riverpod ^3.4.3, go_router ^18.0.2, sqflite ^2.4.4+1,
  dio ^5.11.1, shared_preferences ^2.5.6

Bukti yang kuharapkan: potongan kode per file, lalu aku jalankan
flutter analyze + flutter test dan uji manual 3 query (kosong, cocok, tak cocok).
```

Prompt ini memuat lima slot: tujuan + bukti, arsitektur, larangan, konteks
(file + versi paket), dan cara verifikasi. Tidak ada token atau data pribadi di
dalamnya.

## 2. Output awal AI (draft pertama, apa adanya)

Draft pertama memakai `StateProvider` untuk menyimpan kata kunci dan menaruh
pencarian di provider turunan:

```dart
// lib/features/notes/domain/usecases/search_notes.dart
class SearchNotes {
  const SearchNotes();

  List<Note> call(List<Note> notes, String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return List<Note>.unmodifiable(notes);
    return notes
        .where((note) => note.title.toLowerCase().contains(keyword))
        .toList(growable: false);
  }
}

// notes_providers.dart
final searchNotesProvider = Provider<SearchNotes>((ref) => const SearchNotes());
final noteSearchQueryProvider = StateProvider<String>((ref) => '');

final visibleNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final search = ref.watch(searchNotesProvider);
  final query = ref.watch(noteSearchQueryProvider);
  return ref.watch(notesProvider).whenData((items) => search(items, query));
});
```

Hasil `flutter analyze` pada draft ini **gagal** (lihat Bagian 3).

## 3. Verifikasi langkah demi langkah

### 3.1. Cek API nyata (langkah verify)

`StateProvider` tidak lagi diekspor `flutter_riverpod.dart` di Riverpod 3.
Terbukti dari output analyze, bukan dari dugaan:

```text
$ flutter analyze
  error - The function 'StateProvider' isn't defined. Try importing the library
  that defines 'StateProvider', correcting the name to the name of an existing
  function, or defining a function named 'StateProvider' -
  lib\features\notes\presentation\providers\notes_providers.dart:61:33 -
  undefined_function
1 issue found. (ran in 43.1s)
```

Cek ke paket yang benar-benar terpasang di `pubspec.lock` (3.4.3):

```bash
grep -rln "class StateProvider" \
  ~/AppData/Local/Pub/Cache/hosted/pub.dev/riverpod-3.4.3/lib \
  ~/AppData/Local/Pub/Cache/hosted/pub.dev/flutter_riverpod-3.4.3/lib
# riverpod-3.4.3/lib/src/builder.dart   (dipakai internal)
# riverpod-3.4.3/lib/src/providers/legacy/state_provider.dart

grep -n "legacy" ~/AppData/Local/Pub/Cache/hosted/pub.dev/flutter_riverpod-3.4.3/lib/flutter_riverpod.dart
# (tidak ada baris) -> legacy tidak ikut diekspor
```

Keputusan: `StateProvider` ditolak, diganti `NotifierProvider` seperti pola
`ForceOfflineNotifier` yang sudah ada di fitur posts dan bisa dipakai tanpa
import tambahan.

### 3.2. Perbaikan

```dart
final noteSearchQueryProvider =
    NotifierProvider<NoteSearchQueryNotifier, String>(
      NoteSearchQueryNotifier.new,
    );

class NoteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}
```

### 3.3. Gerbang mesin setelah perbaikan

```text
$ flutter analyze
No issues found! (ran in 11.7s)

$ dart format --set-exit-if-changed .
Formatted 35 files (0 changed) in 0.78 seconds.

$ flutter test
All tests passed! (21 test)
```

### 3.4. Uji manual (emulator `Toyami_Phone`, Android 17)

Database emulator berisi 5 catatan: `Catatan mid review`, `test 3`, `test 2`,
`test`, `Toyami itu seorang vtuber`.

| Query | Hasil yang diharapkan | Hasil nyata |
| --- | --- | --- |
| kosong | semua catatan tampil | 5 catatan tampil |
| `test` | hanya judul yang mengandung "test" | 3 catatan tampil (`test 3`, `test 2`, `test`) |
| `zzz` | empty state "Tidak ada catatan dengan judul ..." | `Tidak ada catatan dengan judul "zzz"` |

Bukti: `screenshots/01_semua_catatan.png`, `screenshots/02_pencarian_cocok.png`,
`screenshots/03_empty_state.png`, `screenshots/04_hasil_test.png`.

## 4. Review AI atas kode sendiri

Prompt review:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

| # | Temuan | Level | Bukti | Keputusan |
| --- | --- | --- | --- | --- |
| R1 | `SearchNotes` memakai `toLowerCase().contains()`, sehingga pencarian ikut mencocokkan huruf di tengah kata dan tidak peduli huruf besar/kecil. Perlu dipastikan perilakunya diuji, bukan diasumsikan | saran | 4 test domain menutup huruf besar/kecil, trim, dan tidak cocok | **Diterima**, test dibuat eksplisit |
| R2 | `visibleNotesProvider` mengembalikan `AsyncValue`, sehingga risiko `whenData` menelan error dan menampilkannya sebagai daftar kosong | saran | Ditambah test `error notesProvider diteruskan, bukan berubah jadi daftar kosong` (ProviderContainer + override error): `state.hasError` benar, `state.hasValue` salah | **Diterima**, test ditambahkan |
| R3 | Pencarian sebaiknya langsung di `NoteRepositoryImpl` dengan `WHERE title LIKE ?` agar tidak memuat semua catatan ke memori | saran | `fetchNotes()` sudah membaca seluruh daftar untuk halaman; filter di SQL akan memaksa query baru dan memutus alur `dirty`/sync yang sudah ada | **Ditolak**, alasan tertulis di Bagian 5 |

## 5. Keputusan yang ditolak (alasan teknis)

**R3 ditolak.** Memindahkan pencarian ke SQL (`WHERE title LIKE ?`) berarti:

1. Setiap ketikan memicu query database baru dari layer data, sehingga UI harus
   menangani debounce dan state loading tambahan.
2. Daftar catatan pada aplikasi ini kecil (catatan pribadi) dan sudah dibaca utuh
   oleh `fetchNotes()` untuk halaman; menyaring di memori tidak menambah biaya
   baca.
3. `NoteRepository` adalah kontrak domain untuk operasi data, bukan tempat aturan
   pencarian. Aturan "cocokkan judul, abaikan besar-kecil huruf" adalah aturan
   bisnis yang harus bisa diuji tanpa SQLite. Codelab Minggu 9 juga meminta filter
   dipindah ke use case domain yang murni.

## 6. Refactor setelah AI

- Filter dipindah penuh ke `SearchNotes` di `domain/usecases`, murni Dart.
- Provider hanya menyusun data: `visibleNotesProvider` menggabungkan
  `notesProvider` + kata kunci lewat use case.
- Halaman tidak lagi menyaring apa pun sendiri; ia hanya menampilkan
  `visibleNotesProvider` dan membedakan dua empty state (belum ada catatan vs
  tidak ada yang cocok).
- Tidak ada import lintas layer baru: `grep` presentasi ke SQLite/Dio tetap 0.
