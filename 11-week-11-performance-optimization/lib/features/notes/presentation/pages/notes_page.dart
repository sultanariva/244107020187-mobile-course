import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const _AddNoteDialog(),
    );
    // `null` berarti dialog dibatalkan; string kosong tetap dikirim ke use case
    // agar pengguna menerima pesan error, bukan tombol yang diam saja.
    if (title == null) return;

    final result = await ref.read(addNoteProvider).call(title: title);
    if (!context.mounted) return;
    if (result.failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.failure!.message)));
      return;
    }
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Halaman ini sengaja tidak me-watch provider data apa pun. Kolom cari,
    // badge, dan daftar punya Consumer sendiri, sehingga mengetik satu huruf
    // tidak me-rebuild Scaffold + AppBar (optimasi Minggu 11).
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _SearchField(),
          ),
        ),
        actions: const [_DirtyBadge()],
      ),
      body: const _NoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Kolom pencarian: satu-satunya widget yang rebuild saat kata kunci berubah.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Nilai awal diambil dari provider supaya teks tidak hilang saat tab
    // dibangun ulang (sejak Minggu 11 tab hanya dibangun ketika aktif).
    _controller = TextEditingController(
      text: ref.read(noteSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) =>
          ref.read(noteSearchQueryProvider.notifier).set(value),
      decoration: const InputDecoration(
        hintText: 'Cari judul catatan',
        prefixIcon: Icon(Icons.search),
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}

/// Badge jumlah catatan belum tersinkron, terpisah dari daftar.
class _DirtyBadge extends ConsumerWidget {
  const _DirtyBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dirtyCount = ref.watch(dirtyCountProvider);
    return dirtyCount.maybeWhen(
      data: (count) => count > 0
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Badge(
                label: Text('$count'),
                child: const Icon(Icons.sync_problem),
              ),
            )
          : const Icon(Icons.cloud_done),
      orElse: () => const SizedBox(width: 40, height: 40),
    );
  }
}

/// Daftar catatan dengan pagination bertahap (20 item per halaman tampilan).
///
/// Catatan: `fetchNotes()` tetap membaca seluruh catatan karena pencarian harus
/// mencakup semuanya. Pagination di sini membatasi jumlah widget yang dibangun
/// sehingga scroll dan rebuild tetap murah. Memindahkan pagination ke SQL
/// (LIMIT/OFFSET) dicatat sebagai pekerjaan berikutnya di README.
class _NoteList extends ConsumerStatefulWidget {
  const _NoteList();

  @override
  ConsumerState<_NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<_NoteList> {
  static const int pageSize = 50;

  final ScrollController _controller = ScrollController();
  int _visibleCount = pageSize;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _controller.removeListener(_maybeLoadMore);
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter > 400) return;
    // Tanpa penjaga ini, setState terpanggil setiap event scroll ketika daftar
    // sudah habis, dan itu justru menambah jank di ujung daftar.
    if (_visibleCount >= _totalCount) return;
    setState(() => _visibleCount += pageSize);
  }

  @override
  Widget build(BuildContext context) {
    // Kata kunci berubah -> mulai lagi dari halaman pertama.
    ref.listen(noteSearchQueryProvider, (_, _) {
      if (!mounted) return;
      setState(() => _visibleCount = pageSize);
      if (_controller.hasClients) _controller.jumpTo(0);
    });

    final notes = ref.watch(visibleNotesProvider);
    final query = ref.watch(noteSearchQueryProvider);

    return notes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        _totalCount = items.length;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                query.trim().isEmpty
                    ? 'Belum ada catatan'
                    : 'Tidak ada catatan dengan judul "$query"',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final shown = items.length < _visibleCount
            ? items.length
            : _visibleCount;

        return ListView.builder(
          controller: _controller,
          itemCount: shown,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, i) {
            final note = items[i];
            return NoteTile(
              note: note,
              onTap: note.id != null
                  ? () => context.push('/note/${note.id}')
                  : null,
              onDelete: () async {
                if (note.id == null) return;
                final result = await ref
                    .read(noteRepositoryProvider)
                    .deleteNote(note.id!);
                if (result.failure != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.failure!.message)),
                  );
                }
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
              },
            );
          },
        );
      },
    );
  }
}

/// Dialog catatan baru sebagai widget ber-`State`, supaya
/// `TextEditingController` benar-benar di-dispose (menutup temuan Minggu 8).
class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog();

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catatan baru'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Judul'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
