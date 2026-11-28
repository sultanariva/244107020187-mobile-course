# Laporan Performa — Minggu 11

- **Tanggal**: 28 November 2026
- **Project**: `week5_offline_notes` (Flutter 3.47.7 / Dart 3.13.5)
- **Perangkat**: emulator `Toyami_Phone`, Android 17 (API 37), x64
- **Mode**: profile (`flutter run --profile`)

## 1. Baseline

Skenario: 200 catatan, scroll cepat 3x, buka detail, kembali, 2 putaran,
didahului 1 putaran pemanasan. Diukur dari VM Service timeline (lihat
`docs/performance-findings.md` Bagian "Cara pengukuran").

| Metrik | Sebelum |
| --- | --- |
| Frame terukur | 132 |
| Rata-rata | 13,16 ms |
| p90 | 25,00 ms |
| p99 | 33,92 ms |
| Terburuk | 72,08 ms |
| Frame jank (>16,67 ms) | 29 (22,0%) |

Data mentah: `docs/timeline-sebelum.json`. Ringkasan visual:
`screenshots/03_metrik_sebelum.png`.

## 2. Optimasi yang diterapkan

| # | Optimasi | File | Alasan dipilih |
| --- | --- | --- | --- |
| O1 | Hanya tab aktif yang dibangun (ganti `IndexedStack`) | `lib/routes.dart` | Menghapus pekerjaan halaman yang tidak terlihat; PostsPage tidak lagi auto-refresh di latar belakang |
| O2 | Pecah halaman Catatan: kolom cari, badge, dan daftar jadi Consumer terpisah | `notes_page.dart` | Mengetik kata kunci tidak lagi me-rebuild `Scaffold`/`AppBar` dan seluruh daftar |
| O3 | Pagination bertahap 50 item + penjaga `_visibleCount >= _totalCount` | `notes_page.dart` | Membatasi jumlah widget yang dibangun saat scroll; penjaga mencegah `setState` berulang di ujung daftar |
| O4 | `ListView.builder` + `select` untuk chat; bubble streaming punya Consumer sendiri; `jumpTo` hanya saat pesan baru | `assistant_page.dart` | Streaming puluhan potongan tidak lagi me-rebuild seluruh halaman |
| O5 | Dialog catatan jadi widget ber-`State` dengan `dispose()` | `notes_page.dart` | Menutup kebocoran `TextEditingController` (issue #5) |

Optimasi yang **tidak** dipakai: `CachedNetworkImage` (aplikasi tidak memuat
gambar jaringan), `RepaintBoundary` manual (ListView.builder sudah menambahkan
repaint boundary per item), cache repository (fitur Posts sudah cache-first).

## 3. Hasil verifikasi

| Metrik | Sebelum | Sesudah | Perubahan |
| --- | --- | --- | --- |
| Frame terukur | 132 | 144 | +9% |
| Rata-rata | 13,16 ms | **11,22 ms** | **−14,7%** |
| p90 | 25,00 ms | **20,46 ms** | **−18,2%** |
| p99 | 33,92 ms | 48,45 ms | +42,8% |
| Terburuk | 72,08 ms | 65,09 ms | −9,7% |
| Frame jank | 29 (22,0%) | **25 (17,4%)** | **−20,9%** |

Data mentah: `docs/timeline-sesudah.json`. Ringkasan visual:
`screenshots/04_metrik_sesudah.png`.

### Catatan penting: p99 naik

Rata-rata, p90, dan jumlah frame jank membaik, tetapi p99 naik (33,92 → 48,45 ms).
Penyebab yang paling masuk akal: pagination memanggil `setState` saat daftar
mendekati ujung, sehingga satu frame harus membangun 50 item sekaligus. Ini
terukur, bukan dugaan: dengan `pageSize` 20 spike p99 lebih buruk lagi
(62,54 ms, max 110,16 ms), dan dengan 50 spike turun ke 48,45 ms. Nilai 50 dipilih
karena memberi keseimbangan terbaik dari dua percobaan.

Percobaan `pageSize`:

| pageSize | avg | p90 | p99 | max | jank |
| --- | --- | --- | --- | --- | --- |
| 20 | 11,22 ms | 19,09 ms | 62,54 ms | 110,16 ms | 15,4% |
| 50 | 11,22 ms | 20,46 ms | 48,45 ms | 65,09 ms | 17,4% |

## 4. Trade-off

| Keputusan | Keuntungan | Biaya |
| --- | --- | --- |
| Tab hanya dibangun saat aktif | Halaman tak terlihat tidak memakan frame/memori | Posisi scroll tab direset saat berpindah; state penting (kata kunci, riwayat chat) tetap aman karena disimpan di provider |
| Pagination di presentation | Scroll murah, jumlah widget terbatas | `fetchNotes()` masih membaca semua baris; pencarian tetap butuh seluruh daftar |
| Penjaga `_visibleCount >= _totalCount` | Menghapus `setState` berulang di ujung daftar | Tidak ada, hanya satu kondisi tambahan |
| `select` pada chat | Rebuild lokal per potongan streaming | Sedikit lebih rumit dibaca dibanding `ref.watch(provider)` |

## 5. Pekerjaan berikutnya (belum dikerjakan)

1. **Pagination di layer data** (`LIMIT/OFFSET` + indeks `title`) supaya
   `fetchNotes()` tidak lagi memuat 200 baris untuk 50 item yang tampil.
   Pencarian perlu strategi khusus (query SQL atau indeks FTS).
2. **Hilangkan spike p99** dengan menunda `setState` pagination sampai scroll
   berhenti (debounce 200-300 ms) atau memakai `ValueNotifier<int>` agar hanya
   bagian daftar yang rebuild.
3. **Uji memori formal**: heap snapshot DevTools sebelum/sesudah navigasi detail
   5x. Pada sesi ini leak controller sudah ditutup lewat kode (O5) dan
   diverifikasi dengan grep + test widget, tetapi snapshot heap tidak diambil
   karena UI DevTools tidak dapat diotomasi.

## 6. Catatan kejujuran

- Screenshot Flame Chart DevTools **tidak** disertakan karena dialog onboarding
  DevTools tidak bisa ditutup lewat klik terprogram (CDP) di lingkungan ini.
  Sebagai gantinya: angka dari VM Service timeline (sumber yang sama dengan
  DevTools) + file JSON mentah di `docs/`.
- Percobaan pertama memakai `integration_test` + `watchPerformance`, tetapi
  gagal karena app tidak bisa membuka koneksi ke VM Service
  (`Bad state: Failed to connect to VM Service at ws://localhost:...`).
  Percobaan kedua memakai `gfxinfo` Android, tetapi Flutter (Impeller) tidak
  mencatat frame ke HWUI sehingga hasilnya 0 frame. Metode ketiga (VM Service
  timeline) yang akhirnya dipakai.
- Angka diukur di emulator, bukan perangkat fisik, sehingga nilai absolutnya
  lebih tinggi daripada perangkat nyata; yang bermakna adalah perbandingan
  sebelum/sesudah dengan skenario dan skrip yang sama.
