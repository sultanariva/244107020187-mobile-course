import '../../../../core/failures.dart';
import '../repositories/post_repository.dart';

/// Use case: refresh posts dari jaringan lalu simpan ke cache.
///
/// Punya logika nyata (>1 langkah: ambil jaringan → tulis cache), sehingga
/// layak menjadi use case.
class RefreshPosts {
  const RefreshPosts(this._repository);

  final PostRepository _repository;

  Future<({bool ok, Failure? failure})> call() async {
    final fetched = await _repository.fetchFromNetwork();
    if (fetched.failure != null) {
      return (ok: false, failure: fetched.failure);
    }
    return _repository.cachePosts(fetched.posts);
  }
}
