import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/local/secure_ai_config_store.dart';
import '../../data/repositories/assistant_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../../domain/usecases/ask_assistant.dart';

/// Wiring DI fitur assistant: satu tempat, widget tidak membuat Dio sendiri.

final aiConfigRepositoryProvider = Provider<AiConfigRepository>((ref) {
  return SecureAiConfigStore();
});

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepositoryImpl(Dio(), ref.watch(aiConfigRepositoryProvider));
});

final askAssistantProvider = Provider<AskAssistant>((ref) {
  return AskAssistant(ref.watch(assistantRepositoryProvider));
});

/// Status konfigurasi AI, dipakai UI untuk memperingatkan API key kosong.
final aiConfigStatusProvider = FutureProvider<bool>((ref) async {
  final apiKey = await ref.watch(aiConfigRepositoryProvider).readApiKey();
  return (apiKey ?? '').trim().isNotEmpty;
});

/// State percakapan: riwayat pesan, teks yang sedang mengalir, dan error.
class ChatState {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.streamingText = '',
    this.isStreaming = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final String streamingText;
  final bool isStreaming;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? streamingText,
    bool? isStreaming,
    Object? error = _keep,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      streamingText: streamingText ?? this.streamingText,
      isStreaming: isStreaming ?? this.isStreaming,
      error: identical(error, _keep) ? this.error : error as String?,
    );
  }

  static const Object _keep = Object();
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<ChatState> {
  /// Pertanyaan terakhir, dipakai tombol "Coba lagi" pada fallback error.
  String _lastQuestion = '';

  @override
  ChatState build() => const ChatState();

  Future<void> send(String question) async {
    if (state.isStreaming) return;

    final result = ref.read(askAssistantProvider)(
      question,
      history: state.messages,
    );

    if (result.failure != null) {
      state = state.copyWith(error: result.failure!.message);
      return;
    }

    _lastQuestion = question.trim();
    state = ChatState(
      messages: [...state.messages, ChatMessage.user(_lastQuestion)],
      isStreaming: true,
    );

    final buffer = StringBuffer();
    try {
      await for (final delta in result.stream!) {
        buffer.write(delta);
        state = state.copyWith(streamingText: buffer.toString());
      }

      final answer = buffer.toString().trim();
      if (answer.isEmpty) {
        state = state.copyWith(
          isStreaming: false,
          streamingText: '',
          error: 'Provider mengirim jawaban kosong. Coba lagi.',
        );
        return;
      }

      state = ChatState(
        messages: [...state.messages, ChatMessage.assistant(answer)],
      );
    } on Failure catch (failure) {
      state = state.copyWith(
        isStreaming: false,
        streamingText: '',
        error: failure.message,
      );
    } catch (error) {
      state = state.copyWith(
        isStreaming: false,
        streamingText: '',
        error: 'Terjadi kesalahan tak terduga: $error',
      );
    }
  }

  /// Mengirim ulang pertanyaan terakhir setelah gagal.
  Future<void> retry() => send(_lastQuestion);

  void dismissError() => state = state.copyWith(error: null);

  void reset() {
    _lastQuestion = '';
    state = const ChatState();
  }
}
