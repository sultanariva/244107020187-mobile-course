# Ringkasan Coverage — Minggu 12

Diukur dengan `flutter test --coverage` (lcov), 28 November 2026.
Data mentah: `docs/lcov.info`.

## Total

| Ukuran | Sebelum minggu 12 | Sesudah |
| --- | --- | --- |
| Test unit + widget | 33 | **68** |
| Baris tertutup | 442/710 (62,3%) | **582/710 (82,0%)** |

Kenaikan 19,7 poin persentase, seluruhnya dari test bermakna (bukan test yang
hanya memanggil getter atau konstruktor).

## Per file

| File | Baris tertutup | % |
| --- | --- | --- |
| `features/notes/data/local/database.dart` | 0/6 | 0,0% |
| `features/posts/data/local/database.dart` | 0/6 | 0,0% |
| `features/assistant/data/local/secure_ai_config_store.dart` | 3/9 | 33,3% |
| `features/settings/presentation/providers/settings_providers.dart` | 7/12 | 58,3% |
| `features/settings/presentation/pages/settings_page.dart` | 56/81 | 69,1% |
| `features/notes/presentation/providers/notes_providers.dart` | 21/30 | 70,0% |
| `features/settings/data/repositories/prefs_repository_impl.dart` | 9/12 | 75,0% |
| `features/posts/presentation/pages/posts_page.dart` | 55/73 | 75,3% |
| `features/assistant/presentation/providers/assistant_providers.dart` | 34/45 | 75,6% |
| `features/posts/presentation/providers/posts_providers.dart` | 7/9 | 77,8% |
| `features/notes/presentation/pages/notes_page.dart` | 86/106 | 81,1% |
| `features/assistant/domain/entities/chat_message.dart` | 5/6 | 83,3% |
| `features/notes/data/repositories/note_repository_impl.dart` | 27/32 | 84,4% |
| `features/assistant/presentation/pages/assistant_page.dart` | 101/110 | 91,8% |
| `features/posts/data/repositories/post_repository_impl.dart` | 21/22 | 95,5% |
| `features/assistant/data/repositories/assistant_repository_impl.dart` | 41/42 | 97,6% |
| `core/failures.dart` | 5/5 | 100,0% |
| `core/format.dart` | 2/2 | 100,0% |
| `features/assistant/data/sse_parser.dart` | 17/17 | 100,0% |
| `features/assistant/domain/usecases/ask_assistant.dart` | 10/10 | 100,0% |
| `features/notes/data/models/note_model.dart` | 21/21 | 100,0% |
| `features/notes/domain/entities/note.dart` | 1/1 | 100,0% |
| `features/notes/domain/usecases/add_note.dart` | 6/6 | 100,0% |
| `features/notes/domain/usecases/get_notes.dart` | 3/3 | 100,0% |
| `features/notes/domain/usecases/search_notes.dart` | 6/6 | 100,0% |
| `features/notes/domain/usecases/sync_notes.dart` | 6/6 | 100,0% |
| `features/notes/presentation/widgets/note_tile.dart` | 11/11 | 100,0% |
| `features/posts/data/models/post_model.dart` | 16/16 | 100,0% |
| `features/posts/domain/entities/post.dart` | 1/1 | 100,0% |
| `features/posts/domain/usecases/refresh_posts.dart` | 4/4 | 100,0% |

## Analisis: yang masih bolong dan alasannya

| Bagian | Status | Alasan belum diuji |
| --- | --- | --- |
| `data/local/database.dart` (notes & posts) | 0% | Hanya berisi `openDatabase` + `onCreate`. Di test, skema yang sama dibuat ulang di database in-memory (`sqflite_common_ffi`), jadi jalur `onCreate` perangkat tidak dieksekusi. Menguji ini butuh `path_provider` palsu; nilainya kecil karena isinya deklaratif. |
| `secure_ai_config_store.dart` | 33% | Butuh `flutter_secure_storage`, yang memanggil channel platform (Keychain/Keystore). Di test unit, channel itu tidak ada. Alternatifnya integration test khusus penyimpanan key, belum dibuat. |
| `settings_page.dart` | 69% | Dialog input API key dan base URL butuh `secure_storage`; sisanya (toggle tema) sudah diuji. |
| `notes_providers.dart` | 70% | Cabang `dirtyCountProvider` yang bergantung pada repositori nyata; bagian filter pencarian sudah 100% di `search_notes`. |

## Cabang penting yang sengaja diuji (bukan mengejar angka)

1. **Error tidak boleh berubah jadi data kosong.** `GetNotes`, `searchNotes`,
   dan `postsProvider` diuji dengan repository yang melempar/mengembalikan
   failure; hasilnya harus `hasError`, bukan daftar kosong.
2. **Uang dan antrean tidak boleh dilaporkan sukses saat gagal.** `SyncNotes`
   mengembalikan `synced = 0` bila `markAllSynced` gagal.
3. **Jaringan gagal tidak boleh bocor sebagai `DioException`.** Tujuh jalur
   (tanpa key, 401, 429, 3xx, 5xx, koneksi putus, stream terputus di tengah)
   semuanya menjadi `Failure` yang bisa ditampilkan UI.
4. **Data korup tidak boleh menjatuhkan seluruh daftar.** Satu baris cache posts
   rusak dilewati, baris lain tetap tampil.
