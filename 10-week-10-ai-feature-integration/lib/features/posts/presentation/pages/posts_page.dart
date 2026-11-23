import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/presentation/providers/notes_providers.dart'
    show dirtyCountProvider, notesProvider, syncNotesProvider;
import '../../domain/entities/post.dart';
import '../providers/posts_providers.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  @override
  void initState() {
    super.initState();
    // Cache-first: isi cache tampil lebih dulu, lalu sekali muat dari jaringan
    // saat tab dibuka. Dijalankan dari widget, bukan dari dalam postsProvider,
    // agar postsProvider tidak menginvalida dirinya sendiri.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfCacheEmpty());
  }

  Future<void> _refreshIfCacheEmpty() async {
    List<Post> cached;
    try {
      cached = await ref.read(postsProvider.future);
    } catch (_) {
      cached = const <Post>[];
    }
    if (!mounted || cached.isNotEmpty) return;
    await _refreshPosts();
  }

  Future<void> _refreshPosts() async {
    if (ref.read(forceOfflineProvider)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offline: refresh ditunda')));
      return;
    }
    final result = await ref.read(refreshPostsProvider).call();
    if (!mounted) return;
    if (result.failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.failure!.message)));
      return;
    }
    ref.invalidate(postsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(postsProvider);
    final forceOffline = ref.watch(forceOfflineProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts (cache-first)'),
        actions: [
          Text(forceOffline ? 'Offline' : 'Online'),
          Switch(
            value: forceOffline,
            onChanged: (v) => ref.read(forceOfflineProvider.notifier).set(v),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: dirtyCount.maybeWhen(
                    data: (c) => Text('Catatan belum tersinkron: $c'),
                    orElse: () => const Text('Catatan belum tersinkron: -'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (ref.read(forceOfflineProvider)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offline: sync ditunda'),
                          ),
                        );
                      }
                      return;
                    }
                    final result = await ref.read(syncNotesProvider).call();
                    ref.invalidate(notesProvider);
                    ref.invalidate(dirtyCountProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.failure != null
                                ? result.failure!.message
                                : 'Tersinkron: ${result.synced} catatan',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Cache kosong. Tarik untuk memuat.'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _refreshPosts,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Muat ulang'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshPosts,
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(
                            items[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            items[i].body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
