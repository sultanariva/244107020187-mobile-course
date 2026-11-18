import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart'
    show dirtyCountProvider;
import 'package:week5_offline_notes/features/posts/domain/entities/post.dart';
import 'package:week5_offline_notes/features/posts/domain/repositories/post_repository.dart';
import 'package:week5_offline_notes/features/posts/presentation/pages/posts_page.dart';
import 'package:week5_offline_notes/features/posts/presentation/providers/posts_providers.dart';

/// Repository palsu: cache lokal dan jaringan dipisah agar alur cache-first
/// bisa diuji tanpa SQLite maupun Dio.
class FakePostRepository implements PostRepository {
  FakePostRepository({this.offline = false});

  final bool offline;
  final List<Post> cache = [];
  int networkCalls = 0;

  @override
  Future<({List<Post> posts, Failure? failure})> fetchCachedPosts() async {
    return (posts: List<Post>.from(cache), failure: null);
  }

  @override
  Future<({List<Post> posts, Failure? failure})> fetchFromNetwork() async {
    networkCalls++;
    if (offline) {
      return (
        posts: const <Post>[],
        failure: const NetworkFailure('offline (simulasi)'),
      );
    }
    return (
      posts: const [Post(id: 1, title: 'Judul dari jaringan', body: 'isi')],
      failure: null,
    );
  }

  @override
  Future<({bool ok, Failure? failure})> cachePosts(List<Post> posts) async {
    cache
      ..clear()
      ..addAll(posts);
    return (ok: true, failure: null);
  }
}

/// Notifier offline yang sudah aktif sejak awal, untuk menguji jalur "tunda".
class AlwaysOfflineNotifier extends ForceOfflineNotifier {
  @override
  bool build() => true;
}

void main() {
  test('postsProvider hanya membaca cache, bukan memanggil jaringan', () async {
    final repo = FakePostRepository();
    repo.cache.add(const Post(id: 7, title: 'Dari cache', body: 'lama'));

    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final posts = await container.read(postsProvider.future);
    expect(posts.single.title, 'Dari cache');
    expect(repo.networkCalls, 0);
  });

  testWidgets('cache kosong memicu satu kali refresh saat tab Posts dibuka', (
    tester,
  ) async {
    final repo = FakePostRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(repo),
          dirtyCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(home: PostsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Sebelum perbaikan, langkah ini melempar Unhandled Exception
    // "A provider cannot depend on itself" dari posts_providers.dart.
    expect(tester.takeException(), isNull);
    expect(repo.networkCalls, 1);
    expect(find.text('Judul dari jaringan'), findsOneWidget);
  });

  testWidgets('mode offline menahan refresh otomatis dan menampilkan tombol', (
    tester,
  ) async {
    final repo = FakePostRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(repo),
          dirtyCountProvider.overrideWith((ref) async => 0),
          forceOfflineProvider.overrideWith(AlwaysOfflineNotifier.new),
        ],
        child: const MaterialApp(home: PostsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.networkCalls, 0);
    expect(find.text('Cache kosong. Tarik untuk memuat.'), findsOneWidget);
    expect(find.text('Muat ulang'), findsOneWidget);
  });
}
