# AI Verification Checklist & Keputusan Final

## Hasil verifikasi (dicatat sebelum menerima draf AI)

| Pertanyaan checklist | Jawaban | Tindakan |
| --- | --- | --- |
| Background handler berupa fungsi top-level dengan `@pragma('vm:entry-point')`? | **Tidak.** Draf menaruhnya di dalam kelas `PushService` | **Ditolak** — dipindah jadi fungsi top-level `firebaseMessagingBackgroundHandler` |
| `onTokenRefresh` benar-benar mengirim token ke backend, bukan hanya log? | **Tidak.** Hanya `debugPrint` | **Ditolak** — `onTokenRefresh.listen(onToken)`, `onToken` = `POST /devices` |
| Foreground memakai local notification manual? | **Tidak.** Hanya `debugPrint` | **Ditolak** — `onMessage.listen(showLocalNotification)` + kanal `pengumuman` |
| Klik dari tiga state masuk ke rute yang benar? | **Sebagian.** Background tidak dinavigasi; `getInitialMessage` absen | **Dikoreksi** — `onMessageOpenedApp` + `getInitialMessage` → `router.go(routeFromMessage(...))` |
| Token/secret tidak di-hardcode dan tidak di-log penuh? | **Tidak.** Mencetak token penuh | **Ditolak** — token tidak pernah di-log; UI hanya menampilkan 12 karakter pertama |
| Apakah API library masih valid? | **Tidak.** `flutter_local_notifications` posisional | **Dikoreksi** — named parameter v22 |

> Kesimpulan: draf AI **ditolak sebagian**. 4 dari 6 poin checklist langsung
> diperbaiki sebelum kode diterima; poin "klik tiga state" menunggu pembuktian
> uji perangkat nyata (tabel di bawah).

## Perbaikan manual atas temuan draf

| Kode | Temuan | Perbaikan | Lokasi akhir |
| --- | --- | --- | --- |
| (A) | Mencetak token penuh | Token tidak di-log; ditampilkan **terpotong** di halaman debug | `lib/pages/home_page.dart` (`_preview`) |
| (B) | `onTokenRefresh` hanya log | `initFcmToken(onToken: registerToken)` → `POST /devices` (`{fcm_token, platform}`) | `lib/messaging/push_service.dart`, `lib/main.dart` |
| (C) | Foreground tanpa notifikasi | `showLocalNotification()` + kanal `pengumuman` (importance high) | `lib/messaging/push_service.dart` |
| (D) | Klik background tidak navigasi | `onMessageOpenedApp.listen((m) => router.go(routeFromMessage(m.data)))` | `lib/messaging/push_service.dart` |
| (E) | Handler di dalam kelas | Dipindah jadi fungsi **top-level** + `@pragma('vm:entry-point')` | `lib/messaging/push_service.dart` |
| (F) | `getInitialMessage` absen | `_handleInitialMessage()` + `pendingDeepLink` | `lib/messaging/push_service.dart` |
| (G) | API posisional | Named parameter v22 (`initialize(settings: ...)`, `show(id: ...)`) | `lib/messaging/push_service.dart` |

## Perbaikan tambahan (ditemukan saat build/analyze)

| Kode | Temuan | Perbaikan |
| --- | --- | --- |
| (H) | Build Android gagal `checkDebugAarMetadata` | Aktifkan core library desugaring + `desugar_jdk_libs:2.1.4` |
| (I) | `switch (DioExceptionType)` tidak exhaustif | Tambah `case DioExceptionType.transformTimeout` (Dio 5.11) |
| (J) | Lint `unnecessary_underscores` pada `(_, __)` | Wildcard `(_, _)` (Dart 3.7+) |
| (K) | `Firebase.initializeApp()` crash tanpa konfigurasi | Dibungkus `try/catch`; app tetap jalan, push nonaktif |
| (L) | AI tidak menyebut jembatan Riverpod→GoRouter | `refreshListenable` (ValueNotifier) agar guard route reaktif |

## Keputusan final (boleh berbeda dari AI)

| Aspek | Keputusan | Alasan |
| --- | --- | --- |
| Background handler | Fungsi top-level (bukan method/kelas) | Wajib: berjalan di isolate terpisah tanpa akses `BuildContext`/Riverpod |
| Token lifecycle | `getToken` + `onTokenRefresh.listen` → `POST /devices` | Backend tidak boleh menyimpan token basi |
| Foreground | Local notification manual | Sistem tidak menampilkan banner otomatis saat app terbuka |
| Deep link | `data.route` → `routeFromMessage()` → `router.go` | Satu sumber rute (`lib/routes.dart`), mudah diuji |
| Guard route | `refreshListenable` Riverpod→GoRouter | Redirect otomatis saat login/logout |
| Penyimpanan token | `flutter_secure_storage` | Token sensitif; SharedPreferences tidak terenkripsi |

## Tabel hasil uji tiga app state (hasil perangkat)

Payload uji (gabungan `notification + data`):

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": { "title": "Jadwal kuliah berubah", "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00" },
    "data": { "route": "/pengumuman/3", "id": "3" }
  }
}
```

| State | Yang diharapkan | Cara uji | Hasil | Bukti |
| --- | --- | --- | --- | --- |
| Foreground | Banner lokal muncul, klik masuk `/pengumuman/3` | App terbuka, kirim dari console | ✅ Banner muncul di atas Home | `screenshots/03_fcm_foreground.png` |
| Background | Banner sistem muncul, klik masuk rute benar | Tekan Home, kirim, klik banner | ✅ Banner muncul di launcher | `screenshots/04_fcm_background.png` |
| Terminated | App terbuka ke rute benar via `getInitialMessage` | Swipe-close, kirim, klik banner | ✅ Banner muncul saat Recents kosong | `screenshots/05_fcm_terminated.png` |