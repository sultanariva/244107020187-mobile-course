import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'local/post.dart';
import 'repositories/note_repository.dart';

/// Toggle simulasi offline deterministik: true = anggap tidak ada koneksi.
final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final postsProvider = FutureProvider<List<Post>>((ref) {
  return loadPostsCacheFirst(ref);
});

/// Alur cache-first: kembalikan cache lokal seketika, lalu refresh
/// background hanya saat cache kosong (agar tidak memicu loop invalidasi).
/// Refresh manual dipicu lewat refreshPosts() (pull-to-refresh / tombol).
Future<List<Post>> loadPostsCacheFirst(Ref ref) async {
  final cached = await readCachedPosts();
  if (cached.isEmpty) {
    refreshPostsInBackground(ref);
  }
  return cached;
}

Future<List<Post>> readCachedPosts() async {
  final db = await openNotesDb();
  final rows = await db.query('cached_posts', orderBy: 'id ASC');
  final posts = <Post>[];
  for (final row in rows) {
    try {
      final list = jsonDecode(row['payload'] as String) as List<dynamic>;
      posts.addAll(list
          .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map))));
    } catch (_) {
      // Payload rusak dilewati agar satu baris korup tidak merusak semua.
    }
  }
  return posts;
}

Future<void> writeCachedPosts(List<Post> posts) async {
  final db = await openNotesDb();
  await db.delete('cached_posts');
  final payload = jsonEncode(posts.map((p) => p.toJson()).toList());
  await db.insert(
    'cached_posts',
    {
      'id': 1,
      'payload': payload,
      'cached_at': DateTime.now().toIso8601String(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Post>> fetchPostsFromNetwork() async {
  final dio = Dio();
  final res = await dio.get('https://jsonplaceholder.typicode.com/posts');
  final list = (res.data as List<dynamic>)
      .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  return list;
}

/// Refresh background: hormati forceOffline, simpan hasil, invalidate provider.
void refreshPostsInBackground(Ref ref) {
  if (ref.read(forceOfflineProvider)) return;
  Future(() async {
    try {
      final fresh = await fetchPostsFromNetwork();
      await writeCachedPosts(fresh);
      ref.invalidate(postsProvider);
    } catch (_) {
      // Gagal jaringan: cache lama tetap dipakai, tidak ada crash.
    }
  });
}

/// Sinkronisasi catatan kotor. Server disimulasikan dengan delay; pada project
/// nyata, kirim tiap catatan dirty ke REST API lalu tandai bersih saat 2xx.
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
