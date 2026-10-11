/// Konstanta rute agar deep link FCM dan GoRouter memakai sumber yang sama.
class Routes {
  Routes._();

  static const String login = '/login';
  static const String home = '/';

  static const String announcementPattern = '/pengumuman/:id';
  static const String announcementIdParam = 'id';

  static String announcement(String id) => '/pengumuman/$id';
}

/// Mengubah payload FCM menjadi path rute (murni, mudah di-unit test).
String routeFromMessage(Map<String, dynamic> data) {
  final raw = (data['route'] ?? '/').toString();
  if (raw.isEmpty) return Routes.home;
  return raw.startsWith('/') ? raw : '/$raw';
}