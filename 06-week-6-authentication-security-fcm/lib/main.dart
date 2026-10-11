import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

/// Router + guard route.
///
/// [ValueNotifier] menjembatani Riverpod ke GoRouter (`refreshListenable`)
/// agar redirect ke `/login` atau `/` otomatis saat status login berubah.
final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ValueNotifier<bool>(
    ref.read(authStateProvider).value ?? false,
  );

  ref.listen<AsyncValue<bool>>(authStateProvider, (_, next) {
    loggedIn.value = next.value ?? false;
  });

  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: loggedIn,
    redirect: (context, state) {
      final isLoggedIn = loggedIn.value;
      final goingToLogin = state.matchedLocation == Routes.login;

      if (!isLoggedIn && !goingToLogin) return Routes.login;
      if (isLoggedIn && goingToLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomePage(),
      ),
      GoRoute(
        path: Routes.announcementPattern,
        builder: (_, state) => AnnouncementPage(
          id: state.pathParameters[Routes.announcementIdParam] ?? '',
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    loggedIn.dispose();
  });

  return router;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Tampilkan UI dulu; inisialisasi Firebase/FCM menyusul agar app tidak
  // menggantung menunggu `getToken()` atau dialog izin notifikasi.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampusNotifyApp(),
    ),
  );

  await _bootstrapPush(container);
}

/// Menyiapkan Firebase + FCM di belakang layar; kegagalan push tidak
/// menghalangi aplikasi tampil.
Future<void> _bootstrapPush(ProviderContainer container) async {
  try {
    final firebaseReady = await initFirebaseAndMessaging(
      registerToken: (token) async {
        // Kirim token perangkat ke backend.
        try {
          await container.read(apiClientProvider).post<dynamic>(
                '/devices',
                data: <String, dynamic>{
                  'fcm_token': token,
                  'platform': _platformName,
                },
              );
        } catch (e) {
          // Backend contoh belum nyata -> cukup dicatat, jangan crash.
          debugPrint('[Main] Gagal mendaftarkan token ke backend: $e');
        }
      },
    );

    // Sambungkan event notifikasi ke router setelah app berjalan.
    if (firebaseReady) {
      bindPushNavigation(container.read(routerProvider));
    }
  } catch (e, s) {
    debugPrint('[Main] Bootstrap FCM gagal (diabaikan): $e\n$s');
  }
}

String get _platformName => switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };

class CampusNotifyApp extends ConsumerWidget {
  const CampusNotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}