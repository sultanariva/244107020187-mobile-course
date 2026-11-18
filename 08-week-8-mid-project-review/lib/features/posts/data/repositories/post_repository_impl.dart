import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../models/post_model.dart';

/// Implementasi [PostRepository] memakai Dio (jaringan) + SQLite (cache).
///
/// Pembuka database dan klien Dio disuntikkan agar mudah diganti fake saat test.
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._openDb, {Dio? dio}) : _dio = dio ?? Dio();

  final Future<Database> Function() _openDb;
  final Dio _dio;

  static const _endpoint = 'https://jsonplaceholder.typicode.com/posts';

  @override
  Future<({List<Post> posts, Failure? failure})> fetchCachedPosts() async {
    try {
      final db = await _openDb();
      final rows = await db.query('cached_posts', orderBy: 'id ASC');
      final posts = <Post>[];
      for (final row in rows) {
        try {
          posts.addAll(PostModel.listFromPayload(row['payload'] as String));
        } catch (_) {
          // Payload rusak dilewati agar satu baris korup tidak merusak semua.
        }
      }
      return (posts: posts, failure: null);
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: LocalFailure('Gagal membaca cache posts: $e'),
      );
    }
  }

  @override
  Future<({List<Post> posts, Failure? failure})> fetchFromNetwork() async {
    try {
      final res = await _dio.get(_endpoint);
      final list = (res.data as List<dynamic>)
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .map((m) => m.toEntity())
          .toList();
      return (posts: list, failure: null);
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: NetworkFailure('Gagal memuat posts: $e'),
      );
    }
  }

  @override
  Future<({bool ok, Failure? failure})> cachePosts(List<Post> posts) async {
    try {
      final db = await _openDb();
      await db.delete('cached_posts');
      await db.insert(
        'cached_posts',
        {
          'id': 1,
          'payload': PostModel.listToPayload(posts),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return (ok: true, failure: null);
    } catch (e) {
      return (
        ok: false,
        failure: LocalFailure('Gagal menyimpan cache posts: $e'),
      );
    }
  }
}
