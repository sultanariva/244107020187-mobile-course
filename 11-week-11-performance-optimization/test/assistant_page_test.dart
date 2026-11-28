import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/assistant/domain/entities/chat_message.dart';
import 'package:week5_offline_notes/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:week5_offline_notes/features/assistant/presentation/pages/assistant_page.dart';
import 'package:week5_offline_notes/features/assistant/presentation/providers/assistant_providers.dart';

class FakeAssistantRepository implements AssistantRepository {
  FakeAssistantRepository({
    this.deltas = const ['Jawaban ', 'bertahap.'],
    this.failure,
  });

  final List<String> deltas;
  final Failure? failure;
  int calls = 0;

  @override
  Stream<String> streamAnswer(List<ChatMessage> messages) async* {
    calls++;
    if (failure != null) throw failure!;
    for (final delta in deltas) {
      yield delta;
    }
  }
}

class FakeAiConfigRepository implements AiConfigRepository {
  FakeAiConfigRepository({this.apiKey, this.baseUrl});

  String? apiKey;
  String? baseUrl;

  @override
  Future<String?> readApiKey() async => apiKey;

  @override
  Future<void> saveApiKey(String value) async => apiKey = value;

  @override
  Future<String?> readBaseUrl() async => baseUrl;

  @override
  Future<void> saveBaseUrl(String value) async => baseUrl = value;
}

Widget _app({
  required FakeAiConfigRepository config,
  required FakeAssistantRepository repository,
}) {
  return ProviderScope(
    overrides: [
      aiConfigRepositoryProvider.overrideWithValue(config),
      assistantRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: AssistantPage()),
  );
}

void main() {
  testWidgets('tanpa API key muncul peringatan, bukan percakapan kosong', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        config: FakeAiConfigRepository(),
        repository: FakeAssistantRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('API key belum diatur'), findsOneWidget);
  });

  testWidgets('jawaban streaming tampil utuh setelah stream selesai', (
    tester,
  ) async {
    final repository = FakeAssistantRepository();
    await tester.pumpWidget(
      _app(
        config: FakeAiConfigRepository(apiKey: 'dummy-key'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo asisten');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Halo asisten'), findsOneWidget);
    expect(find.text('Jawaban bertahap.'), findsOneWidget);
    expect(repository.calls, 1);
  });

  testWidgets('kegagalan jaringan menampilkan fallback dengan tombol ulang', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      failure: const NetworkFailure('Tidak bisa menghubungi layanan AI.'),
    );
    await tester.pumpWidget(
      _app(
        config: FakeAiConfigRepository(apiKey: 'dummy-key'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak bisa menghubungi layanan AI.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
