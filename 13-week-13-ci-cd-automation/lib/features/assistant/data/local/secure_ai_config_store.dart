import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/assistant_repository.dart';

/// Menyimpan API key dan alamat endpoint AI di penyimpanan terenkripsi
/// (Android Keystore lewat flutter_secure_storage).
///
/// API key tidak pernah ditulis di kode sumber maupun di SharedPreferences
/// biasa, sehingga tidak ikut terbaca pada backup teks atau log.
class SecureAiConfigStore implements AiConfigRepository {
  SecureAiConfigStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String apiKeySlot = 'ai_api_key';
  static const String baseUrlSlot = 'ai_base_url';

  @override
  Future<String?> readApiKey() => _storage.read(key: apiKeySlot);

  @override
  Future<void> saveApiKey(String apiKey) {
    return _storage.write(key: apiKeySlot, value: apiKey.trim());
  }

  @override
  Future<String?> readBaseUrl() => _storage.read(key: baseUrlSlot);

  @override
  Future<void> saveBaseUrl(String baseUrl) {
    return _storage.write(key: baseUrlSlot, value: baseUrl.trim());
  }
}
