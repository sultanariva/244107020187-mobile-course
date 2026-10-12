# AI Prompt Challenge — Minggu 7 (Clean Architecture)

Prompt yang dipakai (adaptasi dari codelab ke project nyata `week5_offline_notes`).
Codelab memakai contoh `campus_notify`; project ini adalah **Offline Notes**
(catatan offline + posts cache-first + pengaturan tema), jadi konteksnya
disesuaikan tanpa mengubah maksud pertanyaan.

```text
Project Flutter saya: week5_offline_notes (catatan offline + posts cache-first + pengaturan tema).
Kondisi kini: folder lib/{data, pages, widgets}, kelas Note bercampur mapping
(toMap/fromMap), NoteRepository konkret tanpa interface, widget/halaman membuat
provider sendiri (DI bocor), dan logika sync catatan ada di layer data.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur notes + settings.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

Tanggal penggunaan: 12 Oktober 2026.
Tool: AI coding assistant di dalam sesi praktikum ini.

## Catatan adaptasi

- Codelab mencontohkan `auth + announcements` (project Minggu 6). Project ini
  tidak punya keduanya, sehingga fitur kedua yang direfactor adalah `settings`
  (preferensi tema + last opened).
- Fitur `posts` awalnya dipertahankan layer-first, lalu ikut direfactor penuh
  menjadi `features/posts` (lihat `verification_and_decision.md`).
