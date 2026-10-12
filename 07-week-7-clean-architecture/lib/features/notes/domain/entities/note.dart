/// Entity bisnis murni untuk catatan.
///
/// Tanpa import Flutter, tanpa `toMap`/`fromMap`/`toJson` — mapping data luar
/// hanya hidup di layer `data` (lihat `NoteModel`).
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}
