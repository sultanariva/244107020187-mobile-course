import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/stats_provider.dart';

/// Halaman ringkasan aktivitas. UI ini fokus pada tiga kondisi utama dari
/// AsyncValue: loading, error, dan data siap pakai. Saya menulisnya dengan
/// gaya yang lebih personal agar tidak terlalu mirip dengan template teman.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengamati state asinkron dari provider ringkasan. Saat state berubah,
    // build akan dipanggil ulang secara otomatis oleh Riverpod.
    final ringkasanAsync = ref.watch(ringkasanStatistikProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Aktivitas'),
      ),
      body: ringkasanAsync.when(
        // 1. State loading: tampilkan indikator supaya user tahu proses masih berjalan.
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        // 2. State error: tampilkan pesan dan tombol retry agar user bisa mencoba kembali.
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Data belum bisa dimuat: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(ringkasanStatistikProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        // 3. State data: tampilkan hasil ringkasan dalam bentuk list.
        data: (ringkasan) => ringkasan.isEmpty
            ? const Center(
                child: Text('Belum ada statistik yang bisa ditampilkan'),
              )
            : ListView.builder(
                itemCount: ringkasan.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: Text(ringkasan[index]),
                ),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Ringkasan',
          ),
        ],
      ),
    );
  }
}