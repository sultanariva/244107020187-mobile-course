import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:week5_offline_notes/features/assistant/domain/entities/chat_message.dart';
import 'package:week5_offline_notes/features/assistant/domain/repositories/assistant_repository.dart';

/// Adapter HTTP palsu: tidak ada jaringan sungguhan, respons dikendalikan test.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class FakeAiConfig implements AiConfigRepository {
  FakeAiConfig({
    this.apiKey = 'dummy-key',
    this.baseUrl = 'http://localhost:8787/v1',
  });

  String? apiKey;
  String? baseUrl;

  @override
  Future<String?> readApiKey() async => apiKey;

  @override
  Future<void> saveApiKey(String value) async => apiKey = value;

  @override
  Future<String?> readBaseUrl() async => baseUrl;

  @override
  Future<void> saveBaseUrl(String value) async => baseUrl = value;
}

ResponseBody sseBody(List<String> chunks) {
  return ResponseBody(
    Stream<Uint8List>.fromIterable(
      chunks.map((c) => Uint8List.fromList(utf8.encode(c))),
    ),
    200,
    headers: {
      Headers.contentTypeHeader: ['text/event-stream'],
    },
  );
}

/// Stream yang mengirim satu potongan valid lalu memutus koneksi.
Stream<Uint8List> _putusSetelahSatuPotongan(RequestOptions options) async* {
  yield Uint8List.fromList(
    utf8.encode('data: {"choices":[{"delta":{"content":"Halo"}}]}\n\n'),
  );
  throw DioException(
    requestOptions: options,
    type: DioExceptionType.receiveTimeout,
  );
}

void main() {
  group('AssistantRepositoryImpl', () {
    test('mengalirkan potongan SSE yang terpotong antar chunk', () async {
      final adapter = FakeAdapter(
        (_) async => sseBody([
          'data: {"choices":[{"delta":{"content":"Halo"}}]}\n',
          '\ndata: {"choices":[{"delta":{"content":" dunia"}}]}\n\n',
          'data: [DONE]\n\n',
        ]),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = AssistantRepositoryImpl(
        config: FakeAiConfig(),
        dio: dio,
      );

      final deltas = await repository.streamAnswer(const [
        ChatMessage.user('Halo?'),
      ]).toList();

      expect(deltas, ['Halo', ' dunia']);
    });

    test(
      'mengirim system/user role, model, dan header Authorization',
      () async {
        final adapter = FakeAdapter((_) async => sseBody(['data: [DONE]\n\n']));
        final dio = Dio()..httpClientAdapter = adapter;
        final repository = AssistantRepositoryImpl(
          config: FakeAiConfig(),
          dio: dio,
        );

        await repository.streamAnswer(const [
          ChatMessage.system('instruksi'),
          ChatMessage.user('pertanyaan'),
        ]).toList();

        final request = adapter.requests.single;
        expect(request.path, 'http://localhost:8787/v1/chat/completions');
        expect(request.headers['Authorization'], 'Bearer dummy-key');
        final body = request.data as Map<String, dynamic>;
        expect(body['stream'], isTrue);
        expect(body['model'], AssistantRepositoryImpl.defaultModel);
        final messages = body['messages'] as List<dynamic>;
        expect((messages.first as Map)['role'], 'system');
        expect((messages.last as Map)['role'], 'user');
      },
    );

    test('tanpa API key gagal sebelum menyentuh jaringan', () async {
      final adapter = FakeAdapter((_) async => sseBody(['data: [DONE]\n\n']));
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = AssistantRepositoryImpl(
        config: FakeAiConfig(apiKey: '   '),
        dio: dio,
      );

      await expectLater(
        repository.streamAnswer(const [ChatMessage.user('x')]),
        emitsError(isA<ConfigurationFailure>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('HTTP 401 menjadi ConfigurationFailure dengan pesan key', () async {
      final adapter = FakeAdapter(
        (_) async => ResponseBody.fromString('unauthorized', 401),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = AssistantRepositoryImpl(
        config: FakeAiConfig(),
        dio: dio,
      );

      await expectLater(
        repository.streamAnswer(const [ChatMessage.user('x')]),
        emitsError(
          isA<ConfigurationFailure>().having(
            (e) => e.message,
            'message',
            contains('API key ditolak'),
          ),
        ),
      );
    });

    test('HTTP 429 menjadi NetworkFailure soal kuota', () async {
      final adapter = FakeAdapter(
        (_) async => ResponseBody.fromString('too many requests', 429),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = AssistantRepositoryImpl(
        config: FakeAiConfig(),
        dio: dio,
      );

      await expectLater(
        repository.streamAnswer(const [ChatMessage.user('x')]),
        emitsError(
          isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            contains('Kuota'),
          ),
        ),
      );
    });

    test(
      'kegagalan koneksi menjadi NetworkFailure, bukan exception mentah',
      () async {
        final adapter = FakeAdapter(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'koneksi ditolak',
          ),
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final repository = AssistantRepositoryImpl(
          config: FakeAiConfig(),
          dio: dio,
        );

        await expectLater(
          repository.streamAnswer(const [ChatMessage.user('x')]),
          emitsError(isA<NetworkFailure>()),
        );
      },
    );

    test('HTTP 5xx menjadi NetworkFailure (pesan generik, bukan kode status) '
        '— dicatat sebagai temuan U7', () async {
      final adapter = FakeAdapter(
        (_) async => ResponseBody.fromString('server error', 503),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = AssistantRepositoryImpl(
        config: FakeAiConfig(),
        dio: dio,
      );

      await expectLater(
        repository.streamAnswer(const [ChatMessage.user('x')]),
        emitsError(
          isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            contains('Gagal memanggil layanan AI'),
          ),
        ),
      );
    });

    test(
      'HTTP 3xx ditolak lewat cabang "Provider menolak permintaan"',
      () async {
        final adapter = FakeAdapter(
          (_) async => ResponseBody.fromString('moved', 302),
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final repository = AssistantRepositoryImpl(
          config: FakeAiConfig(),
          dio: dio,
        );

        await expectLater(
          repository.streamAnswer(const [ChatMessage.user('x')]),
          emitsError(
            isA<NetworkFailure>().having(
              (e) => e.message,
              'message',
              contains('HTTP 302'),
            ),
          ),
        );
      },
    );

    test('stream terputus di tengah: potongan pertama terkirim, '
        'lalu NetworkFailure', () async {
      final adapter = FakeAdapter(
        (options) async => ResponseBody(
          _putusSetelahSatuPotongan(options),
          200,
          headers: {
            Headers.contentTypeHeader: ['text/event-stream'],
          },
        ),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = AssistantRepositoryImpl(
        config: FakeAiConfig(),
        dio: dio,
      );

      final deltas = <String>[];
      Object? error;
      try {
        await for (final delta in repository.streamAnswer(const [
          ChatMessage.user('x'),
        ])) {
          deltas.add(delta);
        }
      } catch (e) {
        error = e;
      }

      expect(deltas, ['Halo']);
      expect(error, isA<NetworkFailure>());
      expect((error! as NetworkFailure).message, contains('habis waktu'));
    });
  });
}
