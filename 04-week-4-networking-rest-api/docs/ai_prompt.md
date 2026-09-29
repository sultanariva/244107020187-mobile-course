# AI Prompt Challenge

Prompt yang digunakan untuk meminta assistant membuat repository layer untuk endpoint comments dari JSONPlaceholder:

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error
  ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

Catatan:
- Tujuan prompt ini adalah menguji apakah AI menghasilkan arsitektur yang benar-benar mengikuti pola repository, provider, parsing aman, dan error handling yang dapat dipahami user.
- Prompt awal dapat menghasilkan struktur yang hampir benar, tetapi tetap harus diverifikasi dengan lint, test, dan review logika aplikasi.
