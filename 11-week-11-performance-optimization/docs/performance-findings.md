# Temuan Profiling — Minggu 11

- **Tanggal**: 28 November 2026
- **Project**: `week5_offline_notes` (fitur notes, posts, assistant, settings)
- **Mode**: `flutter run --profile` di emulator `Toyami_Phone` (Android 17 / API 37)
- **Data uji**: 200 catatan di database aplikasi
- **Skenario**: scroll cepat 3x, buka detail, kembali, diulang 2 putaran
  (didahului satu putaran pemanasan agar bukan cold start)

## Cara pengukuran

DevTools Performance tidak bisa diotomasi di sesi ini: dialog onboarding DevTools
(telemetry, About) menolak klik yang dikirim lewat CDP, sehingga tombol Record
tidak bisa ditekan secara terprogram. Karena itu angka diambil dari **VM Service
timeline**, sumber data yang sama yang dipakai tab Performance DevTools:

- `setVMTimelineFlags(['Dart','Embedder','GC'])` lalu `clearVMTimeline()`
- jalankan skenario lewat `adb input`
- `getVMTimeline()`, lalu hitung durasi tiap frame dari pasangan flow `VsyncFlow`

Skrip: `integration_test/perf_notes_test.dart` (percobaan awal, gagal karena
koneksi VM Service dari dalam proses app ditolak) dan pengukur Python yang
dipakai untuk angka final (lihat `docs/performance-report.md`).

## Baseline (sebelum optimasi)

| Metrik | Nilai |
| --- | --- |
| Frame terukur | 132 |
| Rata-rata frame | 13,16 ms |
| p90 | 25,00 ms |
| p99 | 33,92 ms |
| Terburuk | 72,08 ms |
| Frame jank (>16,67 ms) | 29 (22,0%) |

## Temuan

### T1. Empat halaman hidup bersamaan (IndexedStack)

`lib/routes.dart` memakai `IndexedStack` dengan empat anak, sehingga `PostsPage`
tetap ter-mount walau tab Catatan yang aktif. Akibatnya `initState` PostsPage
menjalankan `_refreshIfCacheEmpty()` dan seluruh provider halaman lain tetap
tersubscribe selama aplikasi hidup. Kerja ini tidak terlihat pengguna tetapi
memakan frame dan memori.

Bukti: `IndexedStack` di `routes.dart` (versi sebelum optimasi) dan pemanggilan
refresh di `initState` `posts_page.dart`.

### T2. Mengetik satu huruf me-rebuild seluruh halaman

`NotesPage` (sebelum optimasi) me-watch `visibleNotesProvider` dan
`noteSearchQueryProvider` di level halaman. Setiap perubahan kata kunci
membangun ulang `Scaffold`, `AppBar`, kolom cari, dan seluruh daftar.

Bukti: `ref.watch` di `build()` halaman pada versi sebelum optimasi.

### T3. Daftar membangun semua item sekaligus

`ListView.builder` sudah dipakai, tetapi `itemCount` diset `items.length`
(200 baris). Saat scroll cepat, Flutter harus membangun dan membuang puluhan
`NoteTile` per frame; p90 25 ms menunjukkan frame melewati budget 16,67 ms pada
seperempat frame.

Bukti: metrik baseline p90 = 25,00 ms dan 29 frame jank.

### T4. Streaming chat me-rebuild seluruh halaman per potongan

`AssistantPage` me-watch `chatProvider` utuh dan memakai `ListView(children: ...)`,
serta `ref.listen` yang memanggil `jumpTo` pada setiap perubahan state. Setiap
potongan jawaban (puluhan kali per jawaban) memicu rebuild penuh + scroll jump.

Bukti: `ref.watch(chatProvider)` dan `ListView(children: [...])` pada versi
sebelum optimasi.

### T5. `TextEditingController` di dialog tidak pernah di-dispose

Dialog "Catatan baru" membuat `TextEditingController` di dalam method
`_addNote` dan tidak punya siklus `dispose()`. Setiap kali dialog dibuka,
controller baru tertinggal (temuan issue #5 Minggu 8).

Bukti: `grep -c "TextEditingController()"` = 1 dan `grep -c "\.dispose()"` = 0
pada `notes_page.dart` versi sebelum optimasi.
