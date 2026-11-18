import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/refresh_posts.dart';

/// Satu-satunya tempat wiring dependensi (DI) untuk fitur posts.

// Data layer: database opener + klien Dio disuntikkan lewat implementasi.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(openPostsDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi.
final refreshPostsProvider = Provider<RefreshPosts>((ref) {
  return RefreshPosts(ref.watch(postRepositoryProvider));
});

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

/// Alur cache-first: kembalikan cache lokal seketika, lalu refresh background
/// hanya saat cache kosong (agar tidak memicu loop invalidasi). Refresh manual
/// dipicu lewat pull-to-refresh / tombol Sync.
Future<List<Post>> loadPostsCacheFirst(Ref ref) async {
  final result = await ref.watch(postRepositoryProvider).fetchCachedPosts();
  final cached = result.failure != null ? const <Post>[] : result.posts;
  if (cached.isEmpty) {
    refreshPostsInBackground(ref);
  }
  return cached;
}

/// Refresh background: hormati forceOffline, simpan hasil, invalidate provider.
void refreshPostsInBackground(Ref ref) {
  if (ref.read(forceOfflineProvider)) return;
  Future(() async {
    final result = await ref.read(refreshPostsProvider).call();
    if (result.ok) {
      ref.invalidate(postsProvider);
    }
  });
}
