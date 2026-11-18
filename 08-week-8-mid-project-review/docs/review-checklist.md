# Review Checklist Kesiapan Tengah Semester — Minggu 8

- **Nama Mahasiswa**: Sultan Nashira Ariva
- **NIM**: 244107020187
- **Project yang dinilai**: `week5_offline_notes` (hasil refactor Clean Architecture Minggu 7)
- **Tanggal review**: 18 November 2026
- **Repository**: [244107020187-mobile-course](https://github.com/sultanariva/244107020187-mobile-course)

Dokumen ini adalah nilai kesiapan paruh semester, bukan daftar fitur. Isinya
menjawab satu pertanyaan: apakah fondasi project ini bisa dipercaya untuk
separuh semester berikutnya.

---

## 1. Ringkasan status

| Aspek | Status | Bukti |
| --- | --- | --- |
| Struktur feature-first (tiga grep sterilitas) | ✅ | Bagian 2, semuanya **0 hasil** |
| `flutter analyze` bersih | ✅ | `No issues found! (ran in 7.0s)` |
| `dart format --set-exit-if-changed .` bersih | ✅ | `Formatted 33 files (0 changed)` |
| `flutter test` hijau | ✅ | `All tests passed!` (15 test) |
| PR kecil + commit jelas, di-merge lewat review | ✅ dengan catatan | 2 PR (5 file masing-masing), review **mandiri**, lihat Bagian 4 |
| README, screenshot, cara menjalankan | ✅ | Folder `screenshots/`, README ini, `lib/` dan `test/` tersalin |
| Semua komentar review ditindaklanjuti | ✅ dengan 1 utang | 2 temuan diperbaiki (PR #4), 1 dicatat sebagai issue #5 |

---

## 2. Struktur feature-first (tiga grep sterilitas)

Dijalankan dari `08-week-8-mid-project-review/`:

```bash
# 1. Presentation steril dari akses data mentah (harus NOL)
grep -rho "Dio(\|openDatabase(\|getDatabasesPath(\|jsonDecode(" lib/features/*/presentation | wc -l

# 2. Domain + core steril dari framework & package (harus NOL)
grep -rn "import 'package:flutter\|import 'package:dio\|import 'package:sqflite" \
  lib/features/*/domain lib/core | wc -l

# 3. Presentation tidak mengimpor implementasi data selain lewat provider wiring
grep -rl "data/repositories" lib/features/*/presentation | wc -l
```

| Pemeriksaan | Hasil | Kesimpulan |
| --- | --- | --- |
| Grep 1 — akses data mentah di presentation | **0** | ✅ |
| Grep 2 — framework/paket di domain dan core | **0** | ✅ |
| Grep 3 — file presentation yang menyentuh `data/` | **3** | ✅ wajar: ketiganya file `providers/*_providers.dart` yang menjadi satu-satunya tempat wiring DI |

Bentuk `lib/` masih sama dengan akhir Minggu 7: `core/`, `features/` (notes, posts,
settings), `routes.dart`, dan `main.dart`. Tidak ada fitur baru yang ditambahkan
pada Minggu 8.

---

## 3. Gerbang mesin

```text
$ flutter analyze
Analyzing week5_offline_notes...
No issues found! (ran in 7.0s)

$ dart format --set-exit-if-changed .
Formatted 33 files (0 changed) in 0.31 seconds.

$ flutter test
00:02 +15: All tests passed!
```

Screenshot output lengkap: `screenshots/05_hasil_test.png`.

Catatan jujur: pada awal Minggu 8, `dart format --set-exit-if-changed .` **gagal**
(14 file belum terformat). Perapian dikerjakan sebagai commit tersendiri
(`style: terapkan dart format pada baseline Minggu 8`) supaya diff fitur tetap
kecil dan bisa direview.

Rincian test (15):

| File test | Isi |
| --- | --- |
| `test/add_note_test.dart` (4) | judul kosong, judul spasi saja, trim judul/body, kegagalan database |
| `test/get_notes_test.dart` (2) | use case meneruskan daftar dan failure |
| `test/note_test.dart` (5) | model, serialisasi, entity murni, dua provider dengan fake |
| `test/posts_refresh_test.dart` (3) | provider hanya baca cache, auto-refresh sekali, mode offline menahan refresh |
| `test/widget_test.dart` (1) | halaman Pengaturan menampilkan toggle mode gelap |

---

## 4. Disiplin kolaborasi

### 4.1. Branch

| Branch | Peran | Status |
| --- | --- | --- |
| `main` | Rilis yang selalu bisa dijalankan | Menerima merge `develop` di akhir minggu |
| `develop` | Integrasi mingguan, target semua PR | Aktif, menjadi baseline Minggu 8 |
| `feature/notes-validate-empty-title` | Satu fitur: validasi judul | Sudah di-merge lalu dihapus |
| `fix/posts-refresh-self-invalidation` | Satu perbaikan: refresh cache posts | Sudah di-merge lalu dihapus |

### 4.2. Peta issue dan PR

| Nomor | Jenis | Isi | Status |
| --- | --- | --- | --- |
| #1 | Issue | Tombol Simpan diam saja saat judul kosong | Ditutup oleh PR #2 |
| #2 | PR | `feat(notes)`: validasi judul kosong di use case + test (5 file, +159 −10) | Merged ke `develop` |
| #3 | Issue | Tab Posts melempar `A provider cannot depend on itself` | Ditutup oleh PR #4 |
| #4 | PR | `fix(posts)`: refresh cache dipindah ke widget (5 file, +188 −36) | Merged ke `develop` |
| #5 | Issue | `TextEditingController` di dialog catatan tidak pernah di-dispose | Terbuka, dijadwalkan Minggu 9 |

### 4.3. Keterbatasan yang harus dinyatakan

Repository ini hanya punya satu akun GitHub, sehingga **tidak ada reviewer sejawat
independen**. Review di PR #2 dan #4 dilakukan penulis sendiri dengan prosedur
reviewer: checkout branch, membaca diff, menjalankan tiga gerbang mesin, dan
menguji manual di emulator. Komentar review dan keputusannya tersimpan di PR
masing-masing dan di `docs/ai-review-vs-keputusan.md`.

Konsekuensinya: klaim "di-merge via review sejawat" **tidak** bisa dipenuhi apa
adanya. Yang bisa dibuktikan adalah alur branch, issue, PR, komentar review, dan
keputusan merge yang tercatat. Risiko yang tersisa adalah kesalahan penalaran
penulis sendiri tidak tertangkap pihak kedua; mitigasinya adalah bukti eksekusi
(test, logcat, screenshot), bukan pembacaan kode saja.

---

## 5. Kelengkapan dokumentasi

| Kelengkapan | Status | Letak |
| --- | --- | --- |
| README menjelaskan status paruh semester | ✅ | `README.md` folder ini |
| Peta issue dan PR | ✅ | Bagian 4.2 dokumen ini dan README |
| Cara menjalankan project | ✅ | Bagian 5.1 |
| Screenshot bukti | ✅ | `screenshots/01` sampai `05` |
| Prompt AI, output awal, keputusan final | ✅ | `docs/ai-review-vs-keputusan.md` |
| Nilai kesiapan tengah semester | ✅ | Dokumen ini |

### 5.1. Cara menjalankan

```bash
# Project Flutter yang sebenarnya (bukan folder minggu ini)
cd C:/Users/AXIOO/week5_offline_notes
flutter pub get
flutter analyze
flutter test

# Menjalankan di emulator Android
flutter emulators --launch Toyami_Phone
flutter run -d emulator-5554
```

Folder minggu ini hanya berisi salinan artefak (`lib/`, `test/`, `docs/`,
`screenshots/`), tanpa `pubspec.yaml`, sehingga tidak bisa dijalankan langsung.

---

## 6. Utang teknis dan risiko

| Butir | Dampak | Rencana |
| --- | --- | --- |
| Issue #5: `TextEditingController` tidak di-dispose | Leak kecil pada dialog yang dibuka berulang | Minggu 9, bersama pemindahan dialog ke widget ber-`State` |
| `PostsPage` memegang alur refresh (bukan `AsyncNotifier`) | Logika refresh tersebar di presentation | Minggu 9, pertimbangkan `AsyncNotifier` + `state = AsyncData(...)` |
| Review mandiri, bukan sejawat | Kesalahan penalaran bisa lolos | Cari reviewer kedua atau minta dosen/asisten memeriksa PR |
| `develop` baru dibuat di Minggu 8 | Commit Minggu 1-7 langsung di `main` | Biarkan sebagai riwayat, alur baru dipakai mulai Minggu 8 |
| Belum ada CI (`.github/workflows`) | Gerbang mesin masih dijalankan manual | Dijadwalkan pada Minggu 13 (CI/CD), tetapi draf bisa dimulai lebih awal |

---

## 7. Kesimpulan kesiapan

Fondasi project **siap dilanjutkan** ke paruh kedua semester dengan tiga catatan
terbuka yang sudah tercatat di atas. Struktur feature-first Minggu 7 bertahan
tanpa pelanggaran dependency rule, ketiga gerbang mesin hijau dengan angka nyata,
dan dua bug perilaku ditemukan justru karena aplikasi benar-benar dijalankan
(bukan hanya dibaca). Dua bug itu diperbaiki lewat PR terpisah, satu temuan
lainnya dicatat sebagai issue #5 alih-alih ditambal diam-diam.

Yang belum bisa dipenuhi adalah review sejawat independen karena repository
single-owner. Ini dinyatakan terbuka, bukan diklaim sebagai sudah dilakukan.

