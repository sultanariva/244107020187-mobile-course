import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../sse_parser.dart';

/// Implementasi [AssistantRepository] memakai Dio ke endpoint [OI]-compatible
/// (`POST {baseUrl}/chat/completions`, `stream: true`).
///
/// Kegagalan diubah menjadi [Failure] yang ramah pengguna, sesuai kontrak
/// domain: presentation tidak menerima `DioException` mentah.
class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl(this._dio, this._config, {SseParser? parser})
    : _parser = parser ?? const SseParser();

  final Dio _dio;
  final AiConfigRepository _config;
  final SseParser _parser;

  /// Endpoint bawaan. Bisa diganti lewat Pengaturan (mis. server lokal
  /// `http://10.0.2.2:8787/v1` saat menguji di emulator).
  static const String defaultBaseUrl = 'https://api.inferhub.dev/v1';

  /// Model bawaan mengikuti konfigurasi provider [OI]-compatible yang dipakai
  /// di mesin pengembang. Server yang tidak memakai nama model akan
  /// mengabaikan nilai ini.
  static const String defaultModel = 'inferhub/cb/deepseek-v4.1-flash';

  @override
  Stream<String> streamAnswer(List<ChatMessage> messages) async* {
    final apiKey = (await _config.readApiKey())?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw const ConfigurationFailure(
        'API key belum diatur. Buka Pengaturan lalu simpan API key provider.',
      );
    }

    final savedBaseUrl = (await _config.readBaseUrl())?.trim() ?? '';
    final baseUrl = savedBaseUrl.isEmpty ? defaultBaseUrl : savedBaseUrl;

    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        '$baseUrl/chat/completions',
        data: {
          'model': defaultModel,
          'stream': true,
          'messages': [
            for (final message in messages)
              {'role': message.roleName, 'content': message.content},
          ],
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Accept': 'text/event-stream',
          },
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          // 4xx ditangani sendiri agar pesannya bisa spesifik.
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } on DioException catch (e) {
      throw NetworkFailure(_dioMessage(e));
    }

    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      throw const ConfigurationFailure(
        'API key ditolak provider. Periksa kembali key di Pengaturan.',
      );
    }
    if (status == 429) {
      throw const NetworkFailure(
        'Kuota atau rate limit provider tercapai. Coba lagi nanti.',
      );
    }
    if (status < 200 || status >= 300) {
      throw NetworkFailure('Provider menolak permintaan (HTTP $status).');
    }

    var pending = '';
    try {
      await for (final chunk in response.data!.stream) {
        pending += utf8.decode(chunk, allowMalformed: true);
        final lines = pending.split('\n');
        pending = lines.removeLast();
        for (final line in lines) {
          final delta = _parser.parseLine(line);
          if (delta != null) yield delta;
        }
      }
    } on DioException catch (e) {
      throw NetworkFailure(_dioMessage(e));
    }

    final tail = _parser.parseLine(pending);
    if (tail != null) yield tail;
  }

  String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke layanan AI habis waktu. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak bisa menghubungi layanan AI. Periksa koneksi internet.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server AI tidak valid, permintaan dibatalkan.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        return 'Gagal memanggil layanan AI: ${e.message ?? e.error ?? 'kesalahan tidak dikenal'}';
    }
  }
}
