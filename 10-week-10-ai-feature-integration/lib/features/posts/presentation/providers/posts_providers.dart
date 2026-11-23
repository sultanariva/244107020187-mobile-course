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
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Isi cache lokal (cache-first).
///
/// Refresh jaringan **tidak** dijalankan dari dalam provider ini. Versi
/// sebelumnya memanggil `ref.invalidate(postsProvider)` dari provider yang sama,
/// sehingga Riverpod melempar "A provider cannot depend on itself" dan `Ref`
/// provider sudah dibuang saat refresh selesai. Refresh kini dipicu dari
/// `PostsPage`, tempat `Ref` milik widget tetap valid.
final postsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await ref.watch(postRepositoryProvider).fetchCachedPosts();
  // Kegagalan baca cache diperlakukan sebagai cache kosong; UI menawarkan
  // tombol muat ulang alih-alih layar error.
  if (result.failure != null) return const <Post>[];
  return result.posts;
});
