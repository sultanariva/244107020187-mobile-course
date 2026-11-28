/// Entity bisnis murni untuk post.
///
/// Tanpa import Flutter, tanpa `fromJson`/`toJson` — mapping hanya di layer
/// `data` (lihat `PostModel`).
class Post {
  const Post({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;
}
