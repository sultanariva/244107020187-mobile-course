import 'dart:convert';

/// Pembaca potongan jawaban dari satu baris Server-Sent Events (SSE)
/// berformat [OI]-compatible (`data: {"choices":[{"delta":{"content":"..."}}]}`).
///
/// Dipisah sebagai kelas murni supaya format streaming bisa diuji tanpa HTTP.
class SseParser {
  const SseParser();

  static const String doneToken = '[DONE]';

  /// Mengembalikan potongan teks jika [line] membawa konten, atau `null` untuk
  /// baris kosong, komentar, penanda `[DONE]`, dan JSON yang tidak sesuai.
  String? parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('data:')) return null;

    final payload = trimmed.substring('data:'.length).trim();
    if (payload.isEmpty || payload == doneToken) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;

      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return null;

      final choice = choices.first;
      if (choice is! Map) return null;

      final delta = choice['delta'];
      if (delta is! Map) return null;

      final content = delta['content'];
      if (content is! String || content.isEmpty) return null;

      return content;
    } on FormatException {
      return null;
    }
  }
}
