# Hasil Testing dan Validasi

## 1. Flutter Analyze

Perintah yang dijalankan:

```bash
cd c:/Users/AXIOO/week4_api && flutter analyze
```

Hasil validasi akhir:

```text
Analyzing week4_api...
No issues found! (ran in 3.4s)
```

## 2. Flutter Test

Perintah yang dijalankan:

```bash
cd c:/Users/AXIOO/week4_api && flutter test
```

Hasil validasi akhir:

```text
00:02 +9: All tests passed!
```

## 3. Checklist AI Verification

- UI memanggil Dio secara langsung: Tidak. Akses data melalui repository/provider.
- `fromJson` aman null: Ya. Field yang hilang atau null diganti default.
- `DioExceptionType` dipetakan: Ya. timeout, connectionError, badResponse, serta 404/500 didapatkan dari `friendlyErrorMessage`.
- Base URL dan timeout terpusat: Ya. `createDio()` di `lib/data/api_client.dart` menjadi sumber konfigurasi tunggal.
- Test edge case tambahan: Ya. `Comment.fromJson` dengan field null/hilang ditambahkan.
- UI loading, empty, success, dan error/retry: Lulus melalui widget test.
- Pagination: Test memastikan request ganda dicegah, item halaman digabung, dan request berhenti setelah halaman pendek.
- Tidak ada request HTTP sungguhan: Test provider dan widget menggunakan fake repository.
- Hasil lint/test: Lulus tanpa issue; seluruh 9 test lulus.

## 4. Screenshot Aplikasi

- [Daftar post](../screenshots/Screenshot%202026-09-29%20162412.png)
- [State error](../screenshots/Screenshot%202026-09-29%20162432.png)
- [Pagination](../screenshots/Screenshot%202026-09-29%20163522.png)
- [Detail post](../screenshots/Screenshot%202026-09-29%20164103.png)
- [Tampilan aplikasi](../screenshots/Screenshot%202026-09-29%20171813.png)
