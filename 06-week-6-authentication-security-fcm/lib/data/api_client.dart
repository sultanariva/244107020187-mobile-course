import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

/// Dio dengan 2 perilaku utama:
/// 1. Menyisipkan header `Authorization: Bearer <access>`.
/// 2. Saat 401, refresh **sekali** lalu ulangi request; bila gagal, hapus token.
Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode != 401) {
          return handler.next(e);
        }

        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);

        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);

          final retry = await dio.fetch(
            e.requestOptions
              ..headers['Authorization'] = 'Bearer $renewed',
          );
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh ikut mati -> paksa login ulang
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}