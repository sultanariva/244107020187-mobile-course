# Output Awal AI (Baseline)

Berikut contoh output yang berpotensi dihasilkan oleh AI di tahap awal sebelum verifikasi. Output ini memang terlihat masuk akal, tetapi mengandung masalah yang kemudian diperbaiki manual:

```dart
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        postId: json['postId'] as int,
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        body: json['body'] as String,
      );
}

class CommentRepository {
  CommentRepository(this._dio);
  final Dio _dio;

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    return response.data!
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    final code = error.response?.statusCode;
    if (error.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    if (code == 404) return 'Data tidak ditemukan.';
    if (code != null && code >= 500) return 'Server bermasalah.';
  }
  return 'Terjadi kesalahan.';
}
```

Masalah yang ditemukan pada baseline awal:
- `fromJson` memakai cast langsung (`as int` / `as String`) yang dapat crash jika field null atau hilang.
- `timeout` diatur di tiap request, bukan di client `Dio` yang terpusat.
- fungsi `friendlyErrorMessage` dibuat berulang di beberapa file dan berpotensi konflik.
- repository belum diuji dengan edge case field hilang.
- hasil AI perlu diverifikasi lint + test agar benar-benar aman digunakan.
