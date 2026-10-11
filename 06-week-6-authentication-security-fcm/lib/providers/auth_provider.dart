import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';

/// Penyimpanan token (secure storage).
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Sumber autentikasi (mock, siap diganti Firebase Auth).
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

/// Klien HTTP bersama: sudah membawa access token dan auto-refresh saat 401.
final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Status login (true bila ada access token); dipakai guard route di main.dart.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

/// Access token untuk ditampilkan (dipotong) di halaman debug.
final accessTokenProvider = FutureProvider<String?>((ref) {
  return ref.watch(tokenStoreProvider).readAccess();
});

/// Token FCM perangkat (null bila Firebase belum dikonfigurasi).
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  try {
    return await FirebaseMessaging.instance.getToken();
  } catch (_) {
    return null;
  }
});

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
    ref.invalidate(accessTokenProvider);
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidate(accessTokenProvider);
    ref.invalidateSelf();
  }
}