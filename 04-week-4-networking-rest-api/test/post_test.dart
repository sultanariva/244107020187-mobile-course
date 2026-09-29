import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/network_errors.dart';
import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';

class _FakePostRepository extends PostRepository {
  _FakePostRepository({this.posts = const [], this.error}) : super(Dio());

  final List<Post> posts;
  final Object? error;

  @override
  Future<List<Post>> fetchPosts() async {
    if (error != null) throw error!;
    return posts;
  }
}

class _PagedPostRepository extends PostRepository {
  _PagedPostRepository(this.firstPage) : super(Dio());

  final List<Post> firstPage;
  final nextPage = Completer<List<Post>>();
  final requestedPages = <int>[];

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) {
    requestedPages.add(page);
    if (page == 1) return Future.value(firstPage);
    if (page == 2) return nextPage.future;
    return Future.value(const []);
  }
}

void main() {
  test('Post.fromJson defaults missing fields', () {
    final post = Post.fromJson({'id': 7});

    expect(post.id, 7);
    expect(post.userId, 0);
    expect(post.title, '');
    expect(post.body, '');
  });

  test('Comment.fromJson defaults missing fields and handles nulls', () {
    final comment = Comment.fromJson({
      'id': 12,
      'postId': null,
      'name': null,
      'email': 'guest@example.com',
    });

    expect(comment.id, 12);
    expect(comment.postId, 0);
    expect(comment.name, '');
    expect(comment.email, 'guest@example.com');
    expect(comment.body, '');
  });

  test('friendlyErrorMessage maps connection and 404 errors', () {
    final connectionError = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );
    final notFoundError = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/posts'),
        statusCode: 404,
      ),
    );

    expect(friendlyErrorMessage(connectionError), contains('terhubung'));
    expect(friendlyErrorMessage(notFoundError), contains('tidak ditemukan'));
  });

  test('post provider returns data from a fake repository', () async {
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          _FakePostRepository(
            posts: const [Post(userId: 1, id: 1, title: 'Tes', body: 'Isi')],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final posts = await container.read(postListProvider.future);

    expect(posts, hasLength(1));
    expect(posts.first.title, 'Tes');
  });

  test('post provider propagates repository errors', () async {
    final error = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          _FakePostRepository(error: error),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(postListProvider.future),
      throwsA(isA<DioException>()),
    );
  });

  test('pagination prevents duplicate requests and stops on a short page', () async {
    final firstPage = List.generate(
      10,
      (index) => Post(
        userId: 1,
        id: index + 1,
        title: 'Post ${index + 1}',
        body: 'Isi',
      ),
    );
    final repository = _PagedPostRepository(firstPage);
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final firstPageLoaded = Completer<void>();
    final subscription = container.listen(
      pagedPostsProvider,
      (previous, next) {
        if (next.page == 1 && !firstPageLoaded.isCompleted) {
          firstPageLoaded.complete();
        }
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await firstPageLoaded.future;

    final notifier = container.read(pagedPostsProvider.notifier);
    final loadingNextPage = notifier.loadNextPage();
    await notifier.loadNextPage();

    expect(repository.requestedPages, [1, 2]);
    expect(container.read(pagedPostsProvider).isLoadingMore, isTrue);

    repository.nextPage.complete([
      const Post(userId: 1, id: 11, title: 'Post 11', body: 'Isi'),
    ]);
    await loadingNextPage;

    final state = container.read(pagedPostsProvider);
    expect(state.items, hasLength(11));
    expect(state.hasMore, isFalse);

    await notifier.loadNextPage();
    expect(repository.requestedPages, [1, 2]);
  });
}
