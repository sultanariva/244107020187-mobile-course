import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:week4_api/pages/post_detail_page.dart';
import 'package:week4_api/pages/post_list_page.dart';
import 'package:week4_api/pages/paged_post_page.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PostListPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) => PostDetailPage(
        postId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/paged',
      builder: (context, state) => const PagedPostPage(),
    ),
  ],
);

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
    Widget build(BuildContext context) => MaterialApp.router(
        title: 'Week 4 - REST API',
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: _router,
      );
}