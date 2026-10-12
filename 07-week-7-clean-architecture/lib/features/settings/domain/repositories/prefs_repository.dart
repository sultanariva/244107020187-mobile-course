/// Kontrak preferensi pengguna (tema, waktu terakhir dibuka).
///
/// Interface hidup di domain; implementasi SharedPreferences di data.
abstract class PrefsRepository {
  Future<bool> getDarkMode();

  Future<void> setDarkMode(bool value);

  Future<void> markOpenedNow();

  Future<String?> getLastOpened();
}
