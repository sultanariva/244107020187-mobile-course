import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeFromMessage', () {
    test('route kosong -> home', () {
      expect(routeFromMessage(const <String, dynamic>{}), Routes.home);
    });

    test('route tanpa slash diberi slash di depan', () {
      expect(
        routeFromMessage(const {'route': 'pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('route dengan slash dibiarkan apa adanya', () {
      expect(
        routeFromMessage(const {'route': '/pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('data payload membawa id pengumuman', () {
      const data = <String, dynamic>{'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });
  });

  group('AuthRepository (mock)', () {
    test('login valid mengembalikan access & refresh token', () async {
      final repo = AuthRepository();
      final session = await repo.login(
        email: 'mhs@polinema.ac.id',
        password: '123456',
      );
      expect(session.access, isNotEmpty);
      expect(session.refresh, isNotEmpty);
    });

    test('email tanpa "@" ditolak', () {
      final repo = AuthRepository();
      expect(
        () => repo.login(email: 'mhs', password: '123456'),
        throwsA(isA<Exception>()),
      );
    });

    test('kata sandi kurang dari 6 karakter ditolak', () {
      final repo = AuthRepository();
      expect(
        () => repo.login(email: 'mhs@polinema.ac.id', password: '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('refresh token kosong gagal (paksa login ulang)', () {
      final repo = AuthRepository();
      expect(() => repo.refresh(''), throwsA(isA<Exception>()));
    });

    test('refresh token valid mengembalikan access token baru', () async {
      final repo = AuthRepository();
      final renewed = await repo.refresh('mock-refresh');
      expect(renewed, isNotEmpty);
    });
  });

  group('friendlyApiError', () {
    RequestOptions options() => RequestOptions(path: '/devices');

    test('tanpa koneksi internet', () {
      final error = DioException(
        requestOptions: options(),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyApiError(error), 'Tidak ada koneksi internet.');
    });

    test('timeout', () {
      final error = DioException(
        requestOptions: options(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(friendlyApiError(error), 'Koneksi lambat atau timeout. Coba lagi.');
    });

    test('401 -> sesi berakhir', () {
      final error = DioException(
        requestOptions: options(),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options(),
          statusCode: 401,
        ),
      );
      expect(friendlyApiError(error), 'Sesi berakhir. Silakan login ulang.');
    });

    test('500 -> server bermasalah', () {
      final error = DioException(
        requestOptions: options(),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options(),
          statusCode: 500,
        ),
      );
      expect(friendlyApiError(error), 'Server sedang bermasalah.');
    });

    test('error non-Dio memakai pesan aslinya tanpa prefix', () {
      expect(
        friendlyApiError(Exception('Email atau kata sandi tidak valid')),
        'Email atau kata sandi tidak valid',
      );
    });
  });
}