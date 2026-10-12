# AI Verification Checklist & Keputusan Final — Minggu 7

Dokumen ini mencatat hasil verifikasi usulan AI (`ai_baseline_output.md`)
dan keputusan final yang benar-benar diterapkan.

## 1. Checklist verifikasi (codelab)

| Pertanyaan checklist | Jawaban | Tindakan |
| --- | --- | --- |
| Apakah interface repository di `domain` dan implementasi di `data`? | **Tidak.** AI menaruh interface + impl di satu file `domain/repositories/` | **Ditolak** — interface di `domain/repositories/note_repository.dart`, impl di `data/repositories/note_repository_impl.dart` |
| Apakah `domain` bebas import Flutter/Dio/SQLite/Firebase? | Ya (setelah dipisah) | Diverifikasi dengan grep (bagian 3), bukan dibaca sekilas |
| Apakah AI membuat use case untuk tiap CRUD satu-baris? | **Ya** (get/add/delete/getById/sync) | **Ditolak** — hanya `GetNotes` + `SyncNotes`; CRUD satu-baris cukup repository → notifier |
| Apakah entity bebas mapping (`toMap/fromMap` hanya di model)? | **Tidak.** AI membiarkan mapping menempel di entity | **Dikoreksi** — entity murni di `domain`, mapping di `data/models/note_model.dart` |
| Apakah wiring DI terpusat di provider & widget tidak `new Repository()`? | Ya, tapi AI memakai tipe konkret | **Dikoreksi** — provider mengembalikan tipe abstraksi `NoteRepository` |
| Apakah AI menambah package DI (`get_it`)? | **Ya** | **Ditolak** — codelab meminta Riverpod saja, tanpa package DI tambahan |
| Kontrak sukses/gagal | AI membiarkan exception bocor ke presentation | **Dikoreksi** — record `({data, failure})` + `Failure` ramah pengguna |

## 2. Tabel usulan AI vs keputusan final

| Topik | Usulan AI | Keputusan final | Alasan |
| --- | --- | --- | --- |
| Lokasi interface & impl | Satu file di `domain/repositories/` | Interface di `domain`, impl di `data` | Domain tidak boleh tahu SQLite; dependency mengarah ke dalam |
| Use case | Semua operasi | Hanya `GetNotes` + `SyncNotes` | CRUD satu-baris = over-engineering; `SyncNotes` punya logika nyata (>1 langkah) |
| Entity vs model | Mapping menempel di entity | Entity murni + `NoteModel` (extends + `toEntity()`) | Entity harus bebas `toMap/fromMap` agar murni |
| Kontrak error | Exception bocor | Record `({data, failure})` + `sealed Failure` | Sukses/gagal eksplisit, UI hanya menerima `message` |
| DI | Tipe konkret + `get_it` | Provider Riverpod bertipe abstraksi | Codelab: Riverpod saja; DIP: bergantung pada abstraksi |
| Fitur kedua | (tidak dibahas) | `settings` (prefs interface + impl) | "Jangan biarkan satu fitur bersih dan sisanya kotor" |
| Fitur posts | (dibiarkan di `lib/data`) | Dipindah jadi `features/posts` 3 layer | Agar `lib/` persis bentuk codelab (tanpa `lib/data`/`lib/pages`) |

## 3. Hasil tiga grep sterilitas

Perintah (di PowerShell, pengganti `rg` karena `rg` tidak terpasang):

```powershell
# 1. Presentation steril dari data mentah (harus NOL)
Get-ChildItem -Recurse -File -Include *.dart `
  lib\features\notes\presentation, lib\features\posts\presentation, lib\features\settings\presentation |
  Select-String "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode"

# 2. Domain + core steril dari framework & package (harus NOL)
Get-ChildItem -Recurse -File -Include *.dart `
  lib\features\notes\domain, lib\features\posts\domain, lib\features\settings\domain, lib\core |
  Select-String "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase"

# 3. Static analysis + test
flutter analyze
flutter test
```

Hasil:

| Pemeriksaan | Hasil |
| --- | --- |
| Grep 1 — presentation steril | **0 hasil** ✅ |
| Grep 2 — domain steril | **0 hasil** ✅ |
| `flutter analyze` | **No issues found!** ✅ |
| `flutter test` | **All tests passed! (8 test)** ✅ |

## 4. Keputusan final (ringkas)

1. **Interface di domain, impl di data.** Domain tidak boleh tahu SQLite.
2. **Use case hanya bila ada logika nyata.** `GetNotes` (dipakai test), `SyncNotes`
   (menghitung antrean + menandai bersih), dan `RefreshPosts` (jaringan → cache).
   Baca/CRUD satu-baris langsung repository → notifier.
3. **Entity murni, mapping di model.** `Note`/`Post` tanpa `toMap/fromMap`;
   `NoteModel extends Note` + `toEntity()`.
4. **Kontrak record + `Failure`.** Exception mentah ditangkap di impl dan
   diubah menjadi `LocalFailure`/`NetworkFailure`; UI hanya menampilkan `message`.
5. **DI terpusat di provider Riverpod**, tanpa package DI tambahan.
6. **Opener SQLite per fitur di layer `data`**, sehingga `lib/core` tetap steril
   framework (grep 2 nol hasil).
7. **Deviasi sadar:** fitur kedua adalah `settings` (bukan `auth`/`announcements`)
   karena project ini tidak punya modul tersebut.
