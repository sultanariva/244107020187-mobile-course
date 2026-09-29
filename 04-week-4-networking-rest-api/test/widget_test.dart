import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';
import 'package:week4_api/main.dart';
import 'package:week4_api/pages/paged_post_page.dart';
import 'package:week4_api/pages/post_list_page.dart';

class _FakePostRepository extends PostRepository {
  _FakePostRepository() : super(Dio());

  @override
  Future<List<Post>> fetchPosts() async => const [
    Post(userId: 1, id: 1, title: 'Contoh post', body: 'Isi post'),
  ];

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async =>
      page == 1
          ? const [
              Post(userId: 1, id: 1, title: 'Contoh post', body: 'Isi post'),
            ]
          : const [];
}

class _PendingPostRepository extends PostRepository {
  _PendingPostRepository(this.response) : super(Dio());

  final Completer<List<Post>> response;

  @override
  Future<List<Post>> fetchPosts() => response.future;
}

class _RetryPostRepository extends PostRepository {
  _RetryPostRepository() : super(Dio());

  var fetchCount = 0;

  @override
  Future<List<Post>> fetchPosts() async {
    fetchCount++;
    if (fetchCount == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    return const [
      Post(userId: 1, id: 1, title: 'Contoh post', body: 'Isi post'),
    ];
  }
}

class _PagedWidgetRepository extends PostRepository {
  _PagedWidgetRepository({this.failNextPageOnce = false}) : super(Dio());

  final bool failNextPageOnce;
  final requestedPages = <int>[];
  var _failedNextPage = false;

  final firstPage = List.generate(
    10,
    (index) => Post(
      userId: 1,
      id: index + 1,
      title: 'Paged post ${index + 1}',
      body: 'Isi post',
    ),
  );

  @override
  Future<List<Post>> fetchPosts() async => firstPage;

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    requestedPages.add(page);
    if (page == 1) return firstPage;
    if (page == 2 && failNextPageOnce && !_failedNextPage) {
      _failedNextPage = true;
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    if (page == 2) {
      return const [
        Post(userId: 1, id: 11, title: 'Paged post 11', body: 'Isi post'),
      ];
    }
    return const [];
  }
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows loading then empty state', (tester) async {
    final response = Completer<List<Post>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            _PendingPostRepository(response),
          ),
        ],
        child: const MaterialApp(home: PostListPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada data dari server.'), findsOneWidget);
  });

  testWidgets('shows posts from the repository provider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Posts API'), findsOneWidget);
    expect(find.text('Contoh post'), findsOneWidget);

    await tester.tap(find.text('Contoh post'));
    await tester.pumpAndSettle();

    expect(find.text('Detail 1'), findsOneWidget);
    expect(find.text('Isi post'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka pagination'));
    await tester.pumpAndSettle();

    expect(find.text('Posts Paged'), findsOneWidget);
    expect(find.text('Semua data termuat.'), findsOneWidget);
  });

  testWidgets('loads the next page when the first page cannot scroll', (
    tester,
  ) async {
    _useTallViewport(tester);
    final repository = _PagedWidgetRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PagedPostPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 2]);
    expect(find.text('Paged post 11'), findsOneWidget);
    expect(find.text('Semua data termuat.'), findsOneWidget);
  });

  testWidgets('shows a page error and retries instead of spinning forever', (
    tester,
  ) async {
    _useTallViewport(tester);
    final repository = _PagedWidgetRepository(failNextPageOnce: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PagedPostPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 2]);
    expect(find.textContaining('Tidak dapat terhubung ke server'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 2, 2]);
    expect(find.text('Paged post 11'), findsOneWidget);
    expect(find.text('Semua data termuat.'), findsOneWidget);
  });

  testWidgets('shows connection error and recovers through retry', (tester) async {
    final repository = _RetryPostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PostListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tidak dapat terhubung ke server'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 2);
    expect(find.text('Contoh post'), findsOneWidget);
  });
}
