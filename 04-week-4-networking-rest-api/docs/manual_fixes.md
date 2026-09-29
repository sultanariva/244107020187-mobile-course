# Perbaikan Manual Setelah Review AI

## 1. Parsing aman dari null dan field yang hilang

Awalnya, AI cenderung menggunakan cast langsung seperti `json['name'] as String`, yang akan crash jika JSON tidak lengkap. Perbaikan yang dibuat adalah:

```dart
name: json['name'] as String? ?? '',
email: json['email'] as String? ?? '',
body: json['body'] as String? ?? '',
```

Tujuannya adalah tetap aman walau API mengembalikan JSON dengan field yang hilang atau null.

## 2. Menetapkan timeout di client yang terpusat

Project sudah menggunakan `createDio()` di `lib/data/api_client.dart` dengan:

```dart
connectTimeout: const Duration(seconds: 10),
receiveTimeout: const Duration(seconds: 10),
```

Karena itu, `CommentRepository` tidak perlu menetapkan timeout di tiap method. Ini membuat konfigurasi konsisten dan sesuai checklist: base URL dan timeout terpusat di satu tempat.

## 3. Menghapus duplikasi `friendlyErrorMessage`

Pada awalnya fungsi error mapping dibuat di dua lokasi berbeda (`providers.dart` dan `network_errors.dart`), yang menyebabkan konflik import. Solusi yang dipakai:

- `friendlyErrorMessage` hanya dipertahankan di `lib/data/network_errors.dart`
- UI memanggil fungsi itu dengan import yang jelas
- tidak ada fungsi duplikat yang membingungkan

## 4. Menambahkan provider detail post yang dibutuhkan aplikasi

File `lib/pages/post_detail_page.dart` memanggil `postDetailProvider`, tetapi provider itu sebelumnya tidak ada. Perbaikan:

```dart
final postDetailProvider = FutureProvider.family<Post, int>(...);
```

Dengan ini UI detail post bisa bekerja tanpa langsung memanggil Dio.

## 5. Menambahkan test edge case sendiri

Pada test awal hanya ada happy path. Kami menambahkan edge case `Comment.fromJson` dengan field null/hilang untuk memastikan parsing aman. Selain itu, kami juga memetakan error 404 dan connection error dalam satu test.

## 6. Alasan keputusan teknis

- UI tidak memanggil Dio secara langsung: repository menangani akses data.
- Parser aman: `fromJson` tidak memakai cast mentah.
- Error mapping: semua jenis utama dipetakan ke pesan user-friendly.
- Centralized config: hanya satu `Dio` client yang memiliki timeout dan base URL.
- Testing: edge case `null` dan `missing fields` ditambahkan agar regresi terdeteksi.
