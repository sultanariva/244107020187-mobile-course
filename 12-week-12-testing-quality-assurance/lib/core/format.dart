/// Fungsi format murni (tanpa widget) agar bisa diuji tanpa membangun UI.
library;

/// Format waktu "diperbarui" untuk ditampilkan ke pengguna.
///
/// Mengembalikan representasi waktu lokal yang sama seperti sebelumnya
/// (`DateTime.toLocal().toString()`), kini terpusat di satu tempat.
String formatUpdatedAt(DateTime updatedAt) {
  return updatedAt.toLocal().toString();
}
