import '../entities/note.dart';

/// Use case murni: menyaring catatan berdasarkan judul.
///
/// Tidak menyentuh database maupun Flutter. Daftar catatan diterima sebagai
/// argumen (hasil `GetNotes`), sehingga aturan pencarian bisa diuji tanpa
/// SQLite dan dipakai ulang oleh UI mana pun.
///
/// Aturan yang dipegang:
/// - kata kunci di-`trim()` lebih dulu, jadi spasi di tepi diabaikan;
/// - pencocokan tidak peduli huruf besar/kecil;
/// - kata kunci kosong berarti "tampilkan semua catatan".
class SearchNotes {
  const SearchNotes();

  List<Note> call(List<Note> notes, String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return List<Note>.unmodifiable(notes);
    return notes
        .where((note) => note.title.toLowerCase().contains(keyword))
        .toList(growable: false);
  }
}
