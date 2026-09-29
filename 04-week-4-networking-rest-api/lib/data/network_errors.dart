import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is! DioException) {
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'Koneksi terlalu lama. Periksa jaringan lalu coba lagi.';
  }

  if (error.type == DioExceptionType.connectionError) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
  }

  if (error.type == DioExceptionType.badCertificate) {
    return 'Koneksi ke server tidak dapat diverifikasi.';
  }

  if (error.type == DioExceptionType.badResponse) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 404) {
      return 'Data yang diminta tidak ditemukan.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server sedang mengalami gangguan. Coba lagi nanti.';
    }
    return 'Permintaan gagal. Silakan coba lagi.';
  }

  if (error.type == DioExceptionType.cancel) {
    return 'Permintaan dibatalkan.';
  }

  return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
}
