import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(prefsRepositoryProvider).markOpenedNow();
      ref.invalidate(lastOpenedProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mode gelap'),
            value: darkMode.value ?? false,
            onChanged: darkMode.isLoading
                ? null
                : (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),
          ListTile(
            title: const Text('Terakhir dibuka'),
            subtitle: Text(lastOpened.value ?? '-'),
          ),
          const _AiSettingsCard(),
          if (darkMode.hasError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${darkMode.error}'),
            ),
        ],
      ),
    );
  }
}

/// Kartu pengaturan layanan AI: API key dan alamat endpoint.
///
/// API key disimpan lewat [SecureAiConfigStore] (flutter_secure_storage), bukan
/// di kode sumber atau SharedPreferences biasa. Controller di-dispose pada
/// [dispose] supaya tidak menjadi kebocoran seperti temuan Minggu 8.
class _AiSettingsCard extends ConsumerStatefulWidget {
  const _AiSettingsCard();

  @override
  ConsumerState<_AiSettingsCard> createState() => _AiSettingsCardState();
}

class _AiSettingsCardState extends ConsumerState<_AiSettingsCard> {
  final TextEditingController _apiKey = TextEditingController();
  final TextEditingController _baseUrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _info;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSavedValues);
  }

  @override
  void dispose() {
    _apiKey.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedValues() async {
    final config = ref.read(aiConfigRepositoryProvider);
    final key = await config.readApiKey() ?? '';
    final baseUrl = await config.readBaseUrl() ?? '';
    if (!mounted) return;
    setState(() {
      _apiKey.text = key;
      _baseUrl.text = baseUrl;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _info = null;
    });

    final config = ref.read(aiConfigRepositoryProvider);
    await config.saveApiKey(_apiKey.text);
    await config.saveBaseUrl(_baseUrl.text);
    ref.invalidate(aiConfigStatusProvider);

    if (!mounted) return;
    setState(() {
      _saving = false;
      _info = 'Tersimpan di penyimpanan terenkripsi perangkat.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Layanan AI', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'API key tidak ditulis di kode sumber. Nilainya disimpan '
              'terenkripsi di perangkat ini saja.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKey,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'API key provider',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _baseUrl,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Base URL (opsional)',
                hintText: 'https://api.inferhub.dev/v1',
                helperText:
                    'Kosongkan untuk memakai endpoint bawaan. '
                    'Saat menguji di emulator: http://10.0.2.2:8787/v1',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                ),
                const SizedBox(width: 12),
                if (_info != null)
                  Expanded(
                    child: Text(
                      _info!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
