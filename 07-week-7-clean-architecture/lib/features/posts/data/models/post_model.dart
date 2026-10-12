import 'dart:convert';

import '../../domain/entities/post.dart';

/// Model: representasi data luar (JSON) + mapping ke entity.
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.body,
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );

  /// Membaca daftar post dari payload JSON yang tersimpan di cache.
  static List<Post> listFromPayload(String payload) {
    final list = jsonDecode(payload) as List<dynamic>;
    return list
        .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Mengubah daftar entity menjadi payload JSON untuk disimpan.
  static String listToPayload(List<Post> posts) {
    return jsonEncode(
      posts
          .map((p) => PostModel(
                id: p.id,
                title: p.title,
                body: p.body,
              ).toJson())
          .toList(),
    );
  }

  Post toEntity() => Post(id: id, title: title, body: body);
}
