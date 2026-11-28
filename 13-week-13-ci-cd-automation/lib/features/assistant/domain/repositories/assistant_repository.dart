import '../../../../core/failures.dart';
import '../entities/chat_message.dart';

/// Kontrak percakapan dengan model AI.
///
/// Sengaja berbentuk `Stream<String>` agar jawaban bisa tampil bertahap
/// (streaming), dan kegagalan dikirim sebagai [Failure] di dalam stream,
/// bukan exception mentah dari HTTP.
abstract class AssistantRepository {
  /// Mengirim [history] ke model dan mengalirkan potongan jawaban.
  Stream<String> streamAnswer(List<ChatMessage> history);
}

/// Kontrak penyimpanan konfigurasi AI (API key dan alamat endpoint).
///
/// API key tidak pernah ditulis di kode sumber; implementasinya memakai
/// penyimpanan terenkripsi milik sistem (flutter_secure_storage).
abstract class AiConfigRepository {
  Future<String?> readApiKey();

  Future<void> saveApiKey(String apiKey);

  Future<String?> readBaseUrl();

  Future<void> saveBaseUrl(String baseUrl);
}
