import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/notes_providers.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Diperbarui: ${formatUpdatedAt(note.updatedAt)}'),
                const SizedBox(height: 8),
                if (note.dirty) const Chip(label: Text('belum tersinkron')),
                const Divider(height: 32),
                Text(note.body.isEmpty ? '(tanpa isi)' : note.body),
              ],
            ),
          );
        },
      ),
    );
  }
}
