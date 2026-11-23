import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/assistant/domain/entities/chat_message.dart';
import 'package:week5_offline_notes/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:week5_offline_notes/features/assistant/domain/usecases/ask_assistant.dart';

class FakeAssistantRepository implements AssistantRepository {
  FakeAssistantRepository({this.deltas = const ['Halo, ', 'ini jawaban.']});

  final List<String> deltas;
  List<ChatMessage>? lastMessages;
  int calls = 0;

  @override
  Stream<String> streamAnswer(List<ChatMessage> messages) async* {
    calls++;
    lastMessages = messages;
    for (final delta in deltas) {
      yield delta;
    }
  }
}

void main() {
  test('pertanyaan kosong ditolak tanpa memanggil repository', () {
    final repository = FakeAssistantRepository();
    final result = AskAssistant(repository).call('   ');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.failure!.message, AskAssistant.emptyQuestionMessage);
    expect(result.stream, isNull);
    expect(repository.calls, 0);
  });

  test(
    'system prompt jadi pesan pertama dan pertanyaan jadi pesan terakhir',
    () async {
      final repository = FakeAssistantRepository();
      final result = AskAssistant(repository).call('  Apa isi catatanku?  ');

      expect(result.failure, isNull);
      // Stream bersifat lazy: body repository baru berjalan saat didengarkan.
      await result.stream!.toList();

      final messages = repository.lastMessages!;
      expect(messages.first.content, AskAssistant.systemPrompt);
      expect(messages.first.roleName, 'system');
      expect(messages.last.content, 'Apa isi catatanku?');
      expect(messages.last.isUser, isTrue);
    },
  );

  test('nama peran mengikuti kontrak payload API', () {
    expect(const ChatMessage.system('x').roleName, 'system');
    expect(const ChatMessage.user('x').roleName, 'user');
    expect(const ChatMessage.assistant('x').roleName, 'assistant');
  });

  test('riwayat dipotong maksimal AskAssistant.maxHistory pesan', () async {
    final repository = FakeAssistantRepository();
    final history = [for (var i = 0; i < 10; i++) ChatMessage.user('pesan $i')];

    final result = AskAssistant(repository).call('terakhir', history: history);
    await result.stream!.toList();

    final messages = repository.lastMessages!;
    // 1 system prompt + maxHistory riwayat + 1 pertanyaan baru.
    expect(messages.length, AskAssistant.maxHistory + 2);
    expect(messages[1].content, 'pesan 4');
    expect(messages.last.content, 'terakhir');
  });
}
