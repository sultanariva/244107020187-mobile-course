import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_errors.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

/// Halaman utama setelah login: status sesi, token (dipotong), kontrol topik,
/// dan contoh deep link `/pengumuman/:id`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(accessTokenProvider);
    final fcmAsync = ref.watch(fcmTokenProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.check),
              ),
              title: const Text('Sesi aktif'),
              subtitle: const Text('Anda berhasil masuk.'),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Token perangkat',
            children: [
              _TokenRow(label: 'Access token', valueAsync: accessAsync),
              const Divider(height: 24),
              _TokenRow(label: 'FCM token', valueAsync: fcmAsync),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleTopic(context, ref, subscribe: true),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Subscribe'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleTopic(context, ref, subscribe: false),
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Unsubscribe'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => context.go(Routes.announcement('3')),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Buka pengumuman #3'),
          ),
        ],
      ),
    );
  }

  static Future<void> _toggleTopic(
    BuildContext context,
    WidgetRef ref, {
    required bool subscribe,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (subscribe) {
        await subscribeToTopic(kPengumumanTopic);
      } else {
        await unsubscribeFromTopic(kPengumumanTopic);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            subscribe
                ? 'Berlangganan topik $kPengumumanTopic'
                : 'Berhenti dari topik $kPengumumanTopic',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal: ${friendlyApiError(e)}')),
      );
    }
  }

  /// Tampilkan 12 karakter pertama saja (token penuh tidak pernah di UI).
  static String _preview(String? token) {
    if (token == null || token.isEmpty) return '—';
    if (token.length <= 12) return '$token...';
    return '${token.substring(0, 12)}...';
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.label, required this.valueAsync});

  final String label;
  final AsyncValue<String?> valueAsync;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        valueAsync.when(
          loading: () => const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => const Text('—'),
          data: (token) => Text(
            HomePage._preview(token),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}