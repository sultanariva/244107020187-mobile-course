/// Satu pesan pada percakapan asisten.
///
/// Murni Dart: tanpa Flutter, tanpa JSON. Peran dibatasi dua nilai karena
/// aplikasi ini hanya mengirim riwayat pengguna dan jawaban asisten.
enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  const ChatMessage.user(this.content) : role = ChatRole.user;

  const ChatMessage.assistant(this.content) : role = ChatRole.assistant;

  final ChatRole role;
  final String content;

  bool get isUser => role == ChatRole.user;
}
