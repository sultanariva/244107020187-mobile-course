import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync.dart';
import 'notes_page.dart'
    show dirtyCountProvider, noteRepositoryProvider, notesProvider;

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onChanged: (v) =>
                ref.read(forceOfflineProvider.notifier).set(v),
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
                              content: Text('Offline: sync ditunda')),
                        );
                      }
                      return;
                    }
                    final synced = await syncNotes(
                      ref.read(noteRepositoryProvider),
                    );
                    ref.invalidate(notesProvider);
                    ref.invalidate(dirtyCountProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tersinkron: $synced catatan')),
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
                  ? const Center(
                      child: Text('Cache kosong. Tarik untuk memuat.'),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (ref.read(forceOfflineProvider)) return;
                        try {
                          final fresh = await fetchPostsFromNetwork();
                          await writeCachedPosts(fresh);
                          ref.invalidate(postsProvider);
                        } catch (_) {
                          // Gagal jaringan: cache lama tetap dipakai.
                        }
                      },
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(items[i].title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(items[i].body,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
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
