import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/posts/presentation/pages/posts_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

/// Konstanta rute + GoRouter terpusat (dipisah dari main.dart).
const routeNotes = '/';
const routeNoteDetail = '/note/:id';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: routeNotes, builder: (context, state) => const HomeShell()),
    GoRoute(
      path: routeNoteDetail,
      builder: (context, state) => NoteDetailPage(
        id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
      ),
    ),
  ],
);

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [NotesPage(), PostsPage(), SettingsPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.notes), label: 'Catatan'),
          NavigationDestination(icon: Icon(Icons.article), label: 'Posts'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}
