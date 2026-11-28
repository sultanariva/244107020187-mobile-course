# Matriks Skenario Pengujian — Minggu 12

Setiap fitur utama diuji dengan tiga sudut: **sukses**, **kasus tepi**, dan
**kegagalan**. Kolom "Jenis" mengikuti tiga sudut itu, bukan tingkat kesulitan.

Total: **68 test** (35 di antaranya baru di minggu ini) + 1 integration test.

## 1. Catatan: menambah

| Skenario | Jenis | Test | Hasil |
| --- | --- | --- | --- |
| Judul valid disimpan dan dirapikan (`"  Belanja  "` → `"Belanja"`) | Sukses | `add_note_test.dart`, `notes_add_flow_test.dart` | Lulus |
| Judul kosong ditolak tanpa memanggil repository | Kegagalan | `add_note_test.dart` | Lulus |
| Judul berisi spasi saja ditolak | Tepi | `add_note_test.dart` | Lulus |
| Kegagalan database diteruskan sebagai `Failure`, bukan exception | Kegagalan | `add_note_test.dart` | Lulus |
| Dialog: judul kosong memunculkan SnackBar dan daftar tetap kosong | Kegagalan | `notes_add_flow_test.dart` | Lulus |
| Dialog: judul valid menambah baris dan langsung tampil di daftar | Sukses | `notes_add_flow_test.dart` | Lulus |

## 2. Catatan: membaca dan menghapus

| Skenario | Jenis | Test | Hasil |
| --- | --- | --- | --- |
| `fetchNotes` mengembalikan baris yang baru ditambahkan | Sukses | `note_repository_impl_test.dart` | Lulus |
| Urutan daftar mengikuti `updated_at` terbaru | Tepi | `note_repository_impl_test.dart` | Lulus |
| `fetchNoteById` untuk id yang tidak ada mengembalikan `null` tanpa error | Tepi | `note_repository_impl_test.dart` | Lulus |
| `deleteNote` menghapus baris dan melaporkan `ok` | Sukses | `note_repository_impl_test.dart` | Lulus |
| Database ditutup → `LocalFailure`, daftar kosong | Kegagalan | `note_repository_impl_test.dart` | Lulus |
| `GetNotes` meneruskan daftar dan failure apa adanya | Sukses/Kegagalan | `get_notes_test.dart` | Lulus |
| Model aman terhadap field hilang dan flag `dirty` bertahan | Tepi | `note_test.dart` | Lulus |

## 3. Catatan: pencarian

| Skenario | Jenis | Test | Hasil |
| --- | --- | --- | --- |
| Kata kunci cocok tanpa peduli huruf besar/kecil | Sukses | `search_notes_test.dart` | Lulus |
| Spasi di tepi kata kunci diabaikan | Tepi | `search_notes_test.dart` | Lulus |
| Tidak ada kecocokan → daftar kosong | Tepi | `search_notes_test.dart` | Lulus |
| Error provider tidak berubah menjadi "tidak ada hasil" | Kegagalan | `search_notes_test.dart` | Lulus |
| Empty state membedakan "belum ada catatan" dan "tidak cocok" | Tepi | `search_notes_test.dart` (widget) | Lulus |

## 4. Catatan: antrean sinkronisasi

| Skenario | Jenis | Test | Hasil |
| --- | --- | --- | --- |
| Dua catatan kotor ditandai bersih, `synced = 2` | Sukses | `sync_notes_test.dart` | Lulus |
| Tidak ada catatan kotor → `markAllSynced` tidak dipanggil | Tepi | `sync_notes_test.dart` | Lulus |
| `countDirty` gagal → failure diteruskan, `synced = 0` | Kegagalan | `sync_notes_test.dart` | Lulus |
| `markAllSynced` gagal → tidak dilaporkan sukses | Kegagalan | `sync_notes_test.dart` | Lulus |

## 5. Posts: cache-first

| Skenario | Jenis | Test | Hasil |
| --- | --- | --- | --- |
| Respons jaringan dipetakan menjadi entity | Sukses | `post_repository_impl_test.dart` | Lulus |
| Koneksi gagal → `NetworkFailure`, daftar kosong | Kegagalan | `post_repository_impl_test.dart` | Lulus |
| Simpan cache lalu baca kembali menghasilkan data sama | Sukses | `post_repository_impl_test.dart` | Lulus |
| Cache baru menimpa payload lama, bukan menumpuk baris | Tepi | `post_repository_impl_test.dart` | Lulus |
| Satu baris cache korup dilewati, baris lain tetap terbaca | Tepi | `post_repository_impl_test.dart` | Lulus |
| Cache kosong bukan kegagalan | Tepi | `post_repository_impl_test.dart` | Lulus |
| Database rusak saat menyimpan cache → `LocalFailure` | Kegagalan | `post_repository_impl_test.dart` | Lulus |
| Payload JSON rusak melempar `FormatException` (ditangkap repository) | Kegagalan | `post_model_test.dart` | Lulus |
| `postsProvider` hanya membaca cache, bukan jaringan | Sukses | `posts_refresh_test.dart` | Lulus |
| Cache kosong memicu satu kali refresh saat tab dibuka | Tepi | `posts_refresh_test.dart` | Lulus |
| Mode offline menahan refresh dan menampilkan tombol | Kegagalan | `posts_refresh_test.dart` | Lulus |

## 6. Asisten AI: streaming

| Skenario | Jenis | Test | Hasil |
| --- | --- | --- | --- |
| Potongan SSE yang terpotong antar chunk tetap utuh (`Halo` + ` dunia`) | Sukses | `assistant_repository_impl_test.dart` | Lulus |
| Payload memakai `stream: true`, model bawaan, dan `Bearer` key | Sukses | `assistant_repository_impl_test.dart` | Lulus |
| Tanpa API key gagal sebelum menyentuh jaringan | Kegagalan | `assistant_repository_impl_test.dart` | Lulus |
| HTTP 401 → `ConfigurationFailure` soal API key | Kegagalan | `assistant_repository_impl_test.dart` | Lulus |
| HTTP 429 → `NetworkFailure` soal kuota | Kegagalan | `assistant_repository_impl_test.dart` | Lulus |
| Koneksi putus → `NetworkFailure`, bukan `DioException` mentah | Kegagalan | `assistant_repository_impl_test.dart` | Lulus |
| HTTP 5xx → `NetworkFailure` (pesan generik, dicatat sebagai U7) | Kegagalan | `assistant_repository_impl_test.dart` | Lulus |
| HTTP 3xx ditolak lewat cabang "Provider menolak permintaan (HTTP 302)" | Tepi | `assistant_repository_impl_test.dart` | Lulus |
| Stream terputus di tengah: potongan pertama terkirim, lalu `NetworkFailure` | Kegagalan | `assistant_repository_impl_test.dart` | Lulus |
| Penanda `[DONE]`, komentar SSE, dan delta tanpa `content` diabaikan | Tepi | `sse_parser_test.dart` | Lulus |
| JSON rusak mengembalikan `null`, bukan melempar | Tepi | `sse_parser_test.dart` | Lulus |
| Pertanyaan kosong ditolak tanpa memanggil repository | Kegagalan | `ask_assistant_test.dart` | Lulus |
| Riwayat dipotong ke batas `maxHistory` | Tepi | `ask_assistant_test.dart` | Lulus |
| UI: tanpa API key muncul peringatan, bukan percakapan kosong | Kegagalan | `assistant_page_test.dart` | Lulus |
| UI: jawaban streaming tampil utuh setelah selesai | Sukses | `assistant_page_test.dart` | Lulus |
| UI: kegagalan jaringan menampilkan tombol ulang | Kegagalan | `assistant_page_test.dart` | Lulus |

## 7. Pengaturan

| Skenario | Jenis | Test | Hasil |
| --- | --- | --- | --- |
| Toggle mode gelap tampil dan bisa diubah | Sukses | `widget_test.dart` | Lulus |

## 8. Integration test (perangkat)

| Skenario | Jenis | Berkas | Hasil |
| --- | --- | --- | --- |
| Tambah catatan → muncul di daftar → cari judulnya → buka detail → kembali | Sukses (alur utama) | `integration_test/app_test.dart` | Lulus (36 detik, emulator `Toyami_Phone`) |

Perintah:

```bash
flutter test integration_test/app_test.dart -d emulator-5554
```
