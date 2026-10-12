/// Failure domain: error yang ramah pengguna, murni Dart (tanpa Flutter).
///
/// Repository mengembalikan salah satu turunan ini agar presentation tidak
/// pernah menerima exception mentah dari SQLite/Dio.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Kegagalan pada sumber data lokal (SQLite, SharedPreferences).
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Kegagalan pada sumber data jaringan (Dio/HTTP).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
