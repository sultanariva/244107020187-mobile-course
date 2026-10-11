import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';

/// Kanal notifikasi Android (wajib di Android 8.0+).
const String kPengumumanChannelId = 'pengumuman';
const String kPengumumanChannelName = 'Pengumuman Kampus';

/// Topik broadcast untuk seluruh mahasiswa.
const String kPengumumanTopic = 'pengumuman-kampus';

/// Notifikasi lokal untuk banner manual saat app di foreground.
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

/// Deep link tertunda (dari klik banner ketika router belum siap).
String? pendingDeepLink;

void Function(String route)? _routeListener;

/// Teruskan rute ke router; bila belum siap, tunda (dibaca [bindPushNavigation]).
void _dispatchRoute(String route) {
  final listener = _routeListener;
  if (listener != null) {
    listener(route);
  } else {
    pendingDeepLink = route;
  }
}

/// Handler background WAJIB fungsi top-level + `@pragma('vm:entry-point')`
/// (berjalan di isolate terpisah). Jangan akses BuildContext/Riverpod/plugin UI.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[PushService] Background message: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

/// Inisialisasi plugin notifikasi lokal + buat kanal Android.
Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await localNotifications.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      _dispatchRoute(response.payload ?? Routes.home);
    },
  );

  // importance high -> muncul sebagai heads-up banner.
  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          kPengumumanChannelId,
          kPengumumanChannelName,
          description: 'Notifikasi pengumuman dari kampus.',
          importance: Importance.high,
        ),
      );
}

/// Meminta izin notifikasi runtime (wajib Android 13+ dan iOS).
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

/// Tampilkan notifikasi lokal saat foreground (sistem tidak otomatis).
Future<void> showLocalNotification(RemoteMessage message) async {
  final route = routeFromMessage(message.data);
  await localNotifications.show(
    id: message.hashCode,
    title: message.notification?.title ?? 'Pengumuman',
    body: message.notification?.body ?? '',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        kPengumumanChannelId,
        kPengumumanChannelName,
        channelDescription: 'Notifikasi pengumuman dari kampus.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: route,
  );
}

/// Ambil token FCM, pantau perubahannya ([onToken] dipanggil setiap token
/// berubah), dan berlangganan topik broadcast.
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
  String topic = kPengumumanTopic,
}) async {
  try {
    final token = await FirebaseMessaging.instance
        .getToken()
        .timeout(const Duration(seconds: 10));
    if (token != null) await onToken(token);
  } catch (e) {
    debugPrint(
      '[PushService] getToken gagal (periksa google-services.json / koneksi '
      'Google Play Services): $e',
    );
  }

  // Wajib: teruskan token baru ke backend, bukan sekadar log.
  FirebaseMessaging.instance.onTokenRefresh.listen(
    onToken,
    onError: (Object e) =>
        debugPrint('[PushService] onTokenRefresh error: $e'),
  );

  try {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  } catch (e) {
    debugPrint('[PushService] Gagal berlangganan topik $topic: $e');
  }
}

Future<void> subscribeToTopic(String topic) =>
    FirebaseMessaging.instance.subscribeToTopic(topic);

Future<void> unsubscribeFromTopic(String topic) =>
    FirebaseMessaging.instance.unsubscribeFromTopic(topic);

/// Siapkan Firebase + FCM. Aman bila konfigurasi Firebase belum ada:
/// aplikasi tetap jalan, hanya fitur push yang nonaktif.
Future<bool> initFirebaseAndMessaging({
  required Future<void> Function(String token) registerToken,
}) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[PushService] Firebase belum dikonfigurasi: $e');
    return false;
  }

  try {
    await initLocalNotifications();
  } catch (e) {
    debugPrint('[PushService] initLocalNotifications gagal: $e');
  }

  try {
    await requestNotificationPermission();
  } catch (e) {
    debugPrint('[PushService] requestNotificationPermission gagal: $e');
  }

  try {
    registerBackgroundHandler();
  } catch (e) {
    debugPrint('[PushService] registerBackgroundHandler gagal: $e');
  }

  try {
    await initFcmToken(onToken: registerToken);
  } catch (e) {
    debugPrint('[PushService] initFcmToken gagal: $e');
  }

  return true;
}

/// Sambungkan event notifikasi ke router (panggil setelah `runApp`).
void bindPushNavigation(GoRouter router) {
  _routeListener = router.go;

  // 1. Foreground: banner manual via local notification.
  FirebaseMessaging.onMessage.listen(showLocalNotification);

  // 2. Background: notifikasi diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    router.go(routeFromMessage(message.data));
  });

  // 3. Terminated: aplikasi dibuka dari notifikasi.
  unawaited(_handleInitialMessage(router));
}

Future<void> _handleInitialMessage(GoRouter router) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  final route =
      initial != null ? routeFromMessage(initial.data) : pendingDeepLink;
  if (route != null) {
    pendingDeepLink = null;
    router.go(route);
  }
}