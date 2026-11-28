/// Satu pesan pada percakapan asisten.
///
/// Murni Dart: tanpa Flutter, tanpa JSON. Peran mengikuti nama yang dipakai
/// endpoint [OI]-compatible, sehingga pemetaan ke payload cukup `role.name`.
enum ChatRole { system, user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  const ChatMessage.system(this.content) : role = ChatRole.system;

  const ChatMessage.user(this.content) : role = ChatRole.user;

  const ChatMessage.assistant(this.content) : role = ChatRole.assistant;

  final ChatRole role;
  final String content;

  bool get isUser => role == ChatRole.user;

  /// Nama peran untuk payload API: `system`, `user`, atau `assistant`.
  String get roleName => role.name;
}
