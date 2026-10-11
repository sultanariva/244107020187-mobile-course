import 'package:dio/dio.dart';

/// Mengubah [DioException] menjadi pesan ramah untuk UI (mudah di-unit test).
String friendlyApiError(Object error) {
  if (error is! DioException) {
    return _genericMessage(error);
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi lambat atau timeout. Coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak ada koneksi internet.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      if (code == 401) return 'Sesi berakhir. Silakan login ulang.';
      if (code == 403) return 'Anda tidak memiliki akses.';
      if (code == 404) return 'Data tidak ditemukan.';
      if (code != null && code >= 500) return 'Server sedang bermasalah.';
      return 'Permintaan gagal (${code ?? 'tidak diketahui'}).';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat server tidak valid.';
    case DioExceptionType.unknown:
      return 'Gagal terhubung ke server.';
  }
}

String _genericMessage(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Terjadi kesalahan tak terduga.' : text;
}