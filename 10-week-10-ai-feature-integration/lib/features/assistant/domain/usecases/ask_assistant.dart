import '../../../../core/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/assistant_repository.dart';

/// Use case: menyusun percakapan lalu meminta jawaban asisten.
///
/// Aturan yang dipegang:
/// - pertanyaan kosong ditolak sebelum menyentuh jaringan;
/// - system prompt selalu ikut sebagai pesan pertama, sehingga persona dan
///   batas jawaban tidak ditentukan oleh UI;
/// - riwayat dibatasi jumlahnya agar biaya token tidak tumbuh tanpa kendali.
class AskAssistant {
  const AskAssistant(this._repository);

  final AssistantRepository _repository;

  static const String emptyQuestionMessage = 'Pertanyaan tidak boleh kosong';
  static const String systemPrompt =
      'Kamu asisten catatan pribadi yang ramah. Jawab dalam Bahasa Indonesia, '
      'maksimal 3 kalimat, dan jangan meminta atau menampilkan data pribadi.';

  /// Batas riwayat yang dikirim. Lebih dari ini dibuang dari depan agar
  /// permintaan tetap murah dan tidak melewati batas konteks model.
  static const int maxHistory = 6;

  ({Stream<String>? stream, Failure? failure}) call(
    String question, {
    List<ChatMessage> history = const [],
  }) {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty) {
      return (
        stream: null,
        failure: const ValidationFailure(emptyQuestionMessage),
      );
    }

    final trimmedHistory = history.length > maxHistory
        ? history.sublist(history.length - maxHistory)
        : history;

    final messages = <ChatMessage>[
      const ChatMessage.system(systemPrompt),
      ...trimmedHistory,
      ChatMessage.user(cleanQuestion),
    ];

    return (stream: _repository.streamAnswer(messages), failure: null);
  }
}
