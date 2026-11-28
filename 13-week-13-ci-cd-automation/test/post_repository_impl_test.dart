import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/posts/data/repositories/post_repository_impl.dart';
import 'package:week5_offline_notes/features/posts/domain/entities/post.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );
}

const String _createCache = '''
CREATE TABLE cached_posts(
  id INTEGER PRIMARY KEY,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL
)''';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(_createCache);
  });

  tearDown(() async {
    await db.close();
  });

  PostRepositoryImpl buildRepository({HttpClientAdapter? adapter}) {
    final dio = Dio();
    if (adapter != null) dio.httpClientAdapter = adapter;
    return PostRepositoryImpl(() async => db, dio: dio);
  }

  group('PostRepositoryImpl jaringan', () {
    test('fetchFromNetwork memetakan daftar JSON menjadi entity', () async {
      final repository = buildRepository(
        adapter: FakeAdapter(
          (_) async => jsonBody([
            {'id': 1, 'title': 'Satu', 'body': 'a'},
            {'id': 2, 'title': 'Dua', 'body': 'b'},
          ]),
        ),
      );

      final result = await repository.fetchFromNetwork();

      expect(result.failure, isNull);
      expect(result.posts.map((p) => p.title), ['Satu', 'Dua']);
    });

    test(
      'fetchFromNetwork gagal menjadi NetworkFailure, bukan exception',
      () async {
        final repository = buildRepository(
          adapter: FakeAdapter(
            (options) async => throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        );

        final result = await repository.fetchFromNetwork();

        expect(result.failure, isA<NetworkFailure>());
        expect(result.posts, isEmpty);
        expect(result.failure!.message, contains('Gagal memuat posts'));
      },
    );
  });

  group('PostRepositoryImpl cache', () {
    test(
      'cachePosts lalu fetchCachedPosts mengembalikan data yang sama',
      () async {
        final repository = buildRepository();

        final cached = await repository.cachePosts(const [
          Post(id: 5, title: 'Lima', body: 'isi'),
        ]);
        expect(cached.ok, isTrue);

        final result = await repository.fetchCachedPosts();
        expect(result.failure, isNull);
        expect(result.posts.single.id, 5);
        expect(result.posts.single.title, 'Lima');
      },
    );

    test('cachePosts menimpa payload lama, bukan menumpuk baris', () async {
      final repository = buildRepository();

      await repository.cachePosts(const [Post(id: 1, title: 'Lama', body: '')]);
      await repository.cachePosts(const [Post(id: 2, title: 'Baru', body: '')]);

      final result = await repository.fetchCachedPosts();
      expect(result.posts, hasLength(1));
      expect(result.posts.single.title, 'Baru');
    });

    test('baris cache korup dilewati tanpa merusak hasil lain', () async {
      final repository = buildRepository();
      await db.insert('cached_posts', {
        'id': 1,
        'payload': jsonEncode([
          {'id': 9, 'title': 'Valid', 'body': ''},
        ]),
        'cached_at': '2026-11-28T00:00:00.000',
      });
      await db.insert('cached_posts', {
        'id': 2,
        'payload': '{rusak}',
        'cached_at': '2026-11-28T00:00:01.000',
      });

      final result = await repository.fetchCachedPosts();

      expect(result.failure, isNull);
      expect(result.posts.single.title, 'Valid');
    });

    test('cache kosong bukan kegagalan', () async {
      final result = await buildRepository().fetchCachedPosts();

      expect(result.failure, isNull);
      expect(result.posts, isEmpty);
    });

    test('database rusak menjadi LocalFailure saat menyimpan cache', () async {
      final broken = PostRepositoryImpl(
        () async => throw StateError('db ditutup'),
      );

      final result = await broken.cachePosts(const [
        Post(id: 1, title: 'X', body: ''),
      ]);

      expect(result.ok, isFalse);
      expect(result.failure, isA<LocalFailure>());
    });
  });
}
