# AI Review vs Keputusan Final — Minggu 8

- **Tanggal**: 18 November 2026
- **Objek review**: PR #2 (`feat(notes): validasi judul kosong di use case + test`) dan PR #4 (`fix(posts): refresh cache dipindah ke widget`)
- **Reviewer AI**: AI coding assistant di dalam sesi praktikum ini (model `cbcn/deepseek-v4.1-flash`)
- **Keputusan akhir**: Sultan Nashira Ariva

Dokumen ini menyimpan prompt, output awal AI apa adanya, hasil verifikasi setiap
temuan, dan keputusan final beserta alasannya. Aturan yang dipegang: temuan AI
tidak diterapkan sebelum dibuktikan dengan grep, test yang gagal, atau reproduksi
manual di emulator.

---

## 1. Prompt yang digunakan

Adaptasi dari AI Prompt Challenge codelab ke dua PR nyata:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
PR 1: use case AddNote memvalidasi judul kosong (ValidationFailure) dan
UI menampilkan SnackBar.
PR 2: pemicu refresh cache Posts dipindah dari postsProvider ke PostsPage.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran) + alasan + usulan potongan kode
perbaikan.
```

---

## 2. Output awal AI (apa adanya)

| # | Temuan | Level | Usulan AI |
| --- | --- | --- | --- |
| A1 | `postsProvider` memanggil `ref.invalidate(postsProvider)` dari dalam dirinya sendiri lewat `refreshPostsInBackground`, melanggar aturan Riverpod | blocker | Pindahkan pemicu refresh ke luar provider, misalnya dengan penghitung `postsRefreshTickProvider` yang diawasi `postsProvider` |
| A2 | Empty state tab Posts hanya menampilkan teks "Tarik untuk memuat", padahal `RefreshIndicator` tidak terpasang pada cabang kosong | blocker | Tambahkan tombol `Muat ulang` di empty state dan panggil ulang refresh |
| A3 | `TextEditingController` di `_addNote` dibuat tetapi tidak pernah di-`dispose()` | saran | Bungkus isi dialog sebagai widget ber-`State` lalu dispose di `dispose()` |
| A4 | Validasi judul sebaiknya dilakukan di UI memakai `TextFormField` + `validator`, bukan di use case | saran | Ganti `TextField` menjadi `TextFormField` dengan validator `value.isEmpty` |
| A5 | `trim()` judul sebaiknya dilakukan di `NoteRepositoryImpl` agar UI cukup mengirim apa adanya | saran | Pindahkan `title.trim()` ke dalam `addNote` di layer data |
| A6 | `AddNote` sebaiknya melempar `Exception` agar pemanggil tidak perlu memeriksa `result.failure` | saran | Ganti kontrak record menjadi `Future<Note>` + `throw` |
| A7 | Urutan import dan panjang baris di beberapa file belum konsisten | saran | Rapikan manual sebelum merge |

Output di atas sengaja **tidak** disunting. Beberapa temuan ternyata salah atau
tidak sesuai arsitektur project ini (lihat Bagian 3).

---

## 3. Verifikasi dan keputusan final

| # | Temuan | Bukti verifikasi | Keputusan | Alasan |
| --- | --- | --- | --- | --- |
| A1 | Benar | Reproduksi di emulator: logcat mencatat `Unhandled Exception: A provider cannot depend on itself` dengan stack `refreshPostsInBackground` → `Ref.invalidate` (`posts_providers.dart:55`). Screenshot `03_posts_sebelum_perbaikan.png` | **Diterima, dikerjakan di PR #4** | Bug nyata dan terbukti, bukan dugaan |
| A2 | Benar | Reproduksi manual: cache kosong, layar berhenti di empty state, tidak ada gestur/ tombol aktif. Screenshot `03_posts_sebelum_perbaikan.png` | **Diterima, dikerjakan di PR #4** | Pengguna tidak punya jalan keluar saat cache kosong |
| A3 | Benar | `grep -c "TextEditingController()"` = **1**, `grep -c "\.dispose()"` = **0** pada `notes_page.dart` | **Diterima, ditunda ke issue #5** | Perbaikan yang benar butuh memindahkan dialog ke widget ber-`State`, di luar lingkup PR validasi. Dicatat sebagai issue, bukan ditambal |
| A4 | Tidak diterapkan | `grep -rn "TextFormField\|validator:" lib` = **0** (tidak ada duplikasi aturan); seluruh 15 test lulus dengan validasi di domain | **Ditolak** | Aturan bisnis harus bisa diuji tanpa widget. Validator UI juga bisa dilewati (mis. pemanggil lain use case), dan codelab Minggu 8 meminta validasi di use case + pesan error di UI |
| A5 | Tidak diterapkan | `grep -c "trim()" note_repository_impl.dart` = **0**; `trim()` hanya ada di `AddNote` (domain) | **Ditolak** | Data layer bukan pemilik aturan bisnis. Kalau `trim` ditaruh di repository, test domain tidak lagi membuktikan apa pun tentang validasi |
| A6 | Tidak diterapkan | Kontrak `({data, failure})` dipakai seluruh repository sejak Minggu 7; `sealed class Failure` di `core/failures.dart` | **Ditolak** | Mengembalikan exception ke presentation membatalkan keputusan arsitektur Minggu 7 dan memaksa UI memakai `try/catch` |
| A7 | Tidak diterapkan | `dart format --set-exit-if-changed .` → `Formatted 33 files (0 changed)` | **Ditolak** | Ditangani formatter, bukan komentar review. Justru ini yang mencegah perdebatan gaya di PR |

Ringkasan syarat codelab:

| Syarat | Status |
| --- | --- |
| Minimal 2 temuan AI terbukti benar dengan bukti | ✅ A1 dan A2 (logcat + reproduksi manual), A3 (grep) |
| Minimal 1 temuan ditolak dengan alasan tertulis | ✅ A4, A5, A6, A7 |
| Keputusan final boleh berbeda dari AI selama berargumen | ✅ A1 memakai usulan AI, tetapi pendekatan teknisnya diubah setelah test membuktikan batas Riverpod |

---

## 4. Catatan penting: usulan AI untuk A1 ikut gagal

Usulan awal AI (dan percobaan pertama perbaikan) adalah menambah
`postsRefreshTickProvider` sebagai penghitung, lalu `postsProvider` mengawasi nilai
itu. Implementasi itu **gagal** saat dijalankan:

```text
Expected: <1>
  Actual: <0>
test/posts_refresh_test.dart: networkCalls tidak bertambah
```

Setelah penyebabnya dicetak keluar:

```text
Cannot use the Ref of FutureProvider<List<Post>>#a05e1 after it has been disposed.
```

Artinya `Ref` milik provider sudah dibuang sebelum refresh selesai, sehingga
menaikkan state provider lain dari dalamnya tidak bisa diandalkan. Keputusan akhir
**menyimpang dari usulan AI**: pemicu refresh dipindahkan ke `PostsPage`
(`ConsumerStatefulWidget`), tempat `Ref` milik widget tetap valid selama widget
hidup. Ini contoh bahwa saran AI tetap harus diuji, bukan diikuti.

---

## 5. Bukti tambahan yang dijalankan

```bash
# Gerbang mesin
flutter analyze                          # No issues found!
dart format --set-exit-if-changed .      # Formatted 33 files (0 changed)
flutter test                             # All tests passed! (15 test)

# Sterilitas layer
grep -rho "Dio(\|openDatabase(\|getDatabasesPath(\|jsonDecode(" lib/features/*/presentation | wc -l   # 0
grep -rn "import 'package:flutter\|import 'package:dio\|import 'package:sqflite" lib/features/*/domain lib/core | wc -l   # 0

# Bukti temuan A3
grep -c "TextEditingController()" lib/features/notes/presentation/pages/notes_page.dart   # 1
grep -c "\.dispose()" lib/features/notes/presentation/pages/notes_page.dart               # 0

# Bukti A1 hilang setelah perbaikan
adb logcat -d | grep -c "Unhandled Exception"    # 0
```
