import '../../../../core/failures.dart';
import '../entities/post.dart';

/// Kontrak yang dibutuhkan domain untuk fitur posts.
///
/// Setiap operasi mengembalikan *record* `({data, failure})` agar sukses/gagal
/// eksplisit dan exception tidak bocor ke presentation.
abstract class PostRepository {
  /// Membaca cache lokal (cache-first).
  Future<({List<Post> posts, Failure? failure})> fetchCachedPosts();

  /// Mengambil data segar dari jaringan.
  Future<({List<Post> posts, Failure? failure})> fetchFromNetwork();

  /// Menyimpan hasil jaringan ke cache lokal.
  Future<({bool ok, Failure? failure})> cachePosts(List<Post> posts);
}
