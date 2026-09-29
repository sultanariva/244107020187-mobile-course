import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postListProvider).asData?.value ?? const <Post>[];
    Post? cachedPost;
    for (final post in posts) {
      if (post.id == postId) {
        cachedPost = post;
        break;
      }
    }

    if (cachedPost != null) {
      return _detailScaffold(cachedPost);
    }

    final postAsync = ref.watch(postDetailProvider(postId));
    return Scaffold(
      appBar: AppBar(title: Text('Detail $postId')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(friendlyErrorMessage(error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(postDetailProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: _detailBody,
      ),
    );
  }

  Widget _detailScaffold(Post post) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail ${post.id}')),
      body: _detailBody(post),
    );
  }

  Widget _detailBody(Post post) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(post.title, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 16),
        Text(post.body),
      ],
    );
  }
}
