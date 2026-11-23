# AI Log — Minggu 10 (Integrasi Fitur AI)

- **Tanggal**: 23 November 2026
- **Project**: `week5_offline_notes` (feature-first Clean Architecture, Minggu 7-9)
- **Fitur yang diintegrasikan**: asisten chat dengan **streaming response** ke endpoint
  [OI]-compatible (`POST {baseUrl}/chat/completions`, `stream: true`)
- **AI yang dipakai**: AI coding assistant di sesi praktikum ini
  (model `cbcn/deepseek-v4.1-flash`)

## 1. Prompt inti (lima slot)

```text
Tambah satu fitur AI ke aplikasi catatan Flutter ini: chat asisten dengan
streaming response.

Tujuan: pengguna mengetik pertanyaan, jawaban muncul bertahap (bukan menunggu
lalu tampil sekaligus), ada indikator loading, ada pesan error + tombol coba
lagi bila gagal, dan peringatan bila API key belum diatur.

Arsitektur: feature-first Clean Architecture (presentation -> domain <- data).
Domain tidak boleh mengimpor Flutter/Dio. Kontrak repository di domain,
implementasi Dio di data, state percakapan di Riverpod.

Larangan: jangan menaruh API key di kode sumber atau SharedPreferences biasa
(wajib flutter_secure_storage); jangan mengubah fitur notes/posts/settings yang
sudah jalan selain menambah kartu pengaturan AI; jangan menambah package selain
flutter_secure_storage; jangan pakai StreamBuilder di dalam widget tanpa provider.

Konteks yang ditempel:
- lib/core/failures.dart (sealed Failure)
- lib/features/notes/domain/usecases/get_notes.dart (gaya use case)
- lib/features/posts/presentation/providers/posts_providers.dart (pola Notifier)
- lib/features/settings/presentation/pages/settings_page.dart (halaman pengaturan)
- lib/routes.dart (HomeShell 3 tab)
- pubspec.yaml: flutter_riverpod ^3.4.3, dio ^5.11.1, go_router ^18.0.2,
  sqflite ^2.4.4+1, shared_preferences ^2.5.6

Bukti yang kuharapkan: potongan kode per layer, lalu flutter analyze + flutter
test, uji manual di emulator dengan endpoint mock, dan tabel risiko privasi/biaya.
```

## 2. Output awal AI (draft pertama)

Draft pertama menghasilkan struktur berikut (ringkas):

```text
lib/features/assistant/
├── domain/
│   ├── entities/chat_message.dart            // role user/assistant
│   ├── repositories/assistant_repository.dart // AssistantRepository + AiConfigRepository
│   └── usecases/ask_assistant.dart            // system prompt + batas riwayat
├── data/
│   ├── sse_parser.dart                        // parsing baris "data: {...}"
│   ├── local/secure_ai_config_store.dart      // flutter_secure_storage
│   └── repositories/assistant_repository_impl.dart // Dio + stream
└── presentation/
    ├── providers/assistant_providers.dart     // ChatNotifier + ChatState
    └── pages/assistant_page.dart              // bubble, composer, fallback
```

Draft ini **belum lolos verifikasi**. Empat masalah nyata ditemukan, semuanya
dibuktikan dengan output tool, bukan dugaan:

## 3. Verifikasi dan perbaikan

| # | Masalah | Bukti | Perbaikan |
| --- | --- | --- | --- |
| V1 | Path import `Failure` salah kedalaman (`../../../core/failures.dart`) | `flutter analyze`: `Target of URI doesn't exist: '../../../core/failures.dart'` di 2 file | Diubah ke `../../../../core/failures.dart` |
| V2 | `switch` atas `DioExceptionType` tidak lengkap | `flutter analyze`: `The type 'DioExceptionType' isn't exhaustively matched ... 'DioExceptionType.transformTimeout'` | Ditambah klausa `default` dengan pesan generik |
| V3 | **System prompt terkirim sebagai role `user`** | Log server mock: `"messages":[{"role":"user","content":"Kamu asisten catatan pribadi..."}, ...]` | `ChatRole` ditambah `system`, `ChatMessage.system(...)`, payload memakai `roleName`; ditambah unit test |
| V4 | Unit test gagal karena stream bersifat lazy | `flutter test`: `Null check operator used on a null value` pada dua test | Test mendengarkan stream (`await result.stream!.toList()`) sebelum memeriksa pesan |
| V5 | `AndroidManifest.xml` tidak punya izin `INTERNET` | `grep -c "INTERNET"` = **0** (selama ini tidak dibutuhkan karena app offline-first) | Izin ditambah; cleartext dibatasi hanya untuk `10.0.2.2` dan `127.0.0.1` lewat `network_security_config.xml` |
| V6 | Presentation membuat `Dio()` sendiri, jadi detail HTTP bocor ke luar layer data | `grep -rc "dio"` di `assistant_providers.dart` = **2**, padahal fitur posts tidak begitu | Dio dibuat di konstruktor `AssistantRepositoryImpl` (parameter opsional), presentation jadi 0 kecocokan. Dikerjakan di PR #10 |

V3 adalah temuan paling penting: kode **kompilasi bersih dan test unit lulus**,
tetapi perilakunya salah. Yang menangkapnya adalah log server nyata saat aplikasi
dijalankan di emulator.

## 4. Review AI atas kode yang dihasilkan

Prompt review:

```text
Review kode integrasi AI Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, Dio, secure storage.
Fokus: kebenaran, privasi/biaya, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

| # | Temuan | Level | Bukti | Keputusan |
| --- | --- | --- | --- | --- |
| R1 | System prompt dikirim sebagai `user`, sehingga persona tidak berfungsi sebagai instruksi sistem | blocker | Log mock: `"role":"user"` pada pesan pertama | **Diterima**, diperbaiki + test `nama peran mengikuti kontrak payload API` |
| R2 | API key sebaiknya disimpan di SharedPreferences agar lebih sederhana dan bisa dibaca saat debug | saran | `flutter_secure_storage` sudah menulis ke Keystore; SharedPreferences menyimpan teks biasa dan ikut ke backup | **Ditolak**, alasan privasi di Bagian 5 |
| R3 | Parsing SSE sebaiknya dipisah dari repository agar bisa diuji tanpa HTTP | saran | `SseParser` murni diuji 5 kasus (delta normal, `[DONE]`, komentar, delta tanpa content, JSON rusak) | **Diterima**, sudah berbentuk kelas terpisah |

## 5. Keputusan privasi dan biaya

| Risiko | Mitigasi yang diterapkan | Bukti |
| --- | --- | --- |
| API key bocor lewat repo | Key tidak ada di kode; diisi pengguna di Pengaturan; `grep -rn "sk-\|AIza" lib` = 0 | `screenshots/01_pengaturan_api_key.png` |
| API key terbaca aplikasi lain / backup | Disimpan di `flutter_secure_storage` (Keystore), bukan SharedPreferences | `secure_ai_config_store.dart` |
| Data pribadi terkirim ke model | System prompt melarang meminta data pribadi; riwayat dibatasi 6 pesan | `AskAssistant.systemPrompt`, `AskAssistant.maxHistory` |
| Biaya token membengkak | Riwayat dipotong (maks 6), jawaban diminta maksimal 3 kalimat, tidak ada auto-retry berulang | `ask_assistant.dart`, test `riwayat dipotong maksimal ...` |
| Traffic tidak terenkripsi | `network_security_config.xml`: cleartext **hanya** untuk `10.0.2.2`/`127.0.0.1`, sisanya wajib HTTPS | file konfigurasi di folder `android/` |
| Key dipakai saat uji | Uji manual memakai **mock server lokal** dengan key `dummy-key`, bukan key asli | `docs/` bagian ini + screenshot 02-04 |

## 6. Uji manual di emulator (Toyami_Phone, Android 17)

Endpoint: mock server lokal yang mendengarkan di `0.0.0.0:8787` pada host,
diakses emulator sebagai `http://10.0.2.2:8787/v1`. Mock mengirim 5 potongan SSE
dengan jeda 0,35 detik.

| Skenario | Hasil nyata | Bukti |
| --- | --- | --- |
| Simpan API key + base URL di Pengaturan | Muncul "Tersimpan di penyimpanan terenkripsi perangkat." | `01_pengaturan_api_key.png` |
| Kirim pertanyaan, jawaban mengalir bertahap | Potongan tampil bertahap, akhirnya utuh | `03_streaming_sebagian.png`, `02_chat_jawaban_lengkap.png` |
| Server dimatikan saat mengirim | Kartu error "Tidak bisa menghubungi layanan AI. Periksa koneksi internet." + tombol "Coba lagi" | `04_error_fallback.png` |
| Tekan "Coba lagi" setelah server hidup | Jawaban tampil normal, kartu error hilang | `02_chat_jawaban_lengkap.png` |
| Payload yang benar-benar dikirim aplikasi | `"role":"system"` untuk system prompt, model, `stream: true` | log mock server (Bagian 3 V3) |

Catatan jujur: panggilan ke provider sungguhan (inferhub/Gemini) **tidak**
dilakukan pada sesi ini karena tidak ada API key yang boleh dipakai tanpa izin
pemiliknya. Yang dibuktikan adalah seluruh jalur aplikasi (Dio, streaming SSE,
parsing, state, UI, fallback) terhadap server yang berbicara protokol yang sama.
