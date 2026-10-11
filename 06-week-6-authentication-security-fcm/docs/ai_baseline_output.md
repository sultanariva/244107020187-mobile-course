# Output AI Awal (Baseline)

Ringkasan output yang dihasilkan AI coding assistant sebelum verifikasi manual
(disimpan apa adanya sebagai bukti proses):

```text
PushService untuk Campus Notification App:

class PushService {
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await FirebaseMessaging.instance.requestPermission();
    await setupToken();
    listenMessages();
  }

  Future<void> setupToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM TOKEN: $token');

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('Token refreshed: $newToken');
    });

    await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  }

  void listenMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground: ${message.notification?.title}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Opened: ${message.data['route']}');
    });
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint('Background: ${message.messageId}');
  }
}
```

Output ini **tidak langsung diterima**. Temuan pada checklist verifikasi
adalah (ditandai `(A)`–`(G)`):

1. **(A) Mencetak token penuh.** `debugPrint('FCM TOKEN: $token')` melanggar
   prinsip keamanan (token tidak boleh muncul di log/screenshot).
2. **(B) `onTokenRefresh` hanya dicetak.** Token baru tidak pernah dikirim ke
   backend, sehingga backend menyimpan token basi.
3. **(C) Foreground tanpa notifikasi lokal.** `onMessage` hanya `debugPrint`;
   karena sistem tidak menampilkan banner otomatis saat app terbuka, banner
   tidak akan muncul.
4. **(D) Klik (background) tidak dinavigasikan.** `onMessageOpenedApp` tidak
   memanggil router, jadi `data.route` diabaikan.
5. **(E) Background handler di dalam kelas.** Handler berada di dalam
   `PushService`, padahal harus fungsi **top-level** agar berjalan di isolate
   terpisah.
6. **(F) `getInitialMessage()` tidak dipanggil.** State terminated tidak
   membuka rute yang benar saat app diluncurkan dari notifikasi.
7. **(G) API `flutter_local_notifications` lama.** Parameter posisional
   (`initialize(settings)`, `show(id, title, ...)`) tidak lagi valid di v22.

Selain temuan di atas, AI tidak menyebut cara menyambungkan status login
(Riverpod) ke GoRouter untuk guard route.