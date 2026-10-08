# Output AI Awal (Baseline)

Ringkasan output yang dihasilkan AI coding assistant sebelum verifikasi manual
(disimpan apa adanya sebagai bukti proses):

```text
Untuk Offline Notes, rekomendasi saya:
- Preferensi tema: SharedPreferences (sederhana, key-value).
- Catatan: Hive, karena NoSQL dan cepat, cocok untuk cache objek.
  Skema box:
    Box<Note> notesBox;
    class Note { String title; String body; int updatedAt; }
  Ambil semua catatan: notesBox.values.toList() — reaktif, cukup
  gunakan watch() agar UI selalu update real-time.
- Alternatif: Drift untuk aplikasi besar, tapi boilerplate-nya besar.
- sqflite hanya perlu jika ada relasi kompleks; untuk catatan biasa
  tidak perlu.
Performa: Hive dijamin real-time karena otomatis memantau perubahan box,
lebih baik dari SQLite yang butuh query ulang manual.
```

Output ini **tidak langsung diterima**. Temuan pada checklist verifikasi
adalah:

1. **Skema tanpa antrean sync.** Model `Note` hanya punya `title`, `body`,
   `updatedAt` — tidak ada kolom/flag `dirty`. Ini hanya CRUD polos, padahal
   kebutuhan aplikasi adalah offline-first dengan dirty flag.
2. **Klaim "real-time" Hive tidak tepat.** Hive box biasa tidak otomatis
   memantau perubahan kecuali memakai `watch()` stream secara eksplisit.
   Klaim ini asumsi, bukan didukung API nyata.
3. **Rekomendasi Hive untuk catatan diperdebatkan.** Tanpa dirty flag dan
   dukungan query terstruktur (WHERE dirty = 1, ORDER BY updated_at), Hive
   kurang cocok untuk antrean sinkronisasi. SQLite (sqflite) lebih pas.
4. **Boilerplate Hive diremehkan.** Untuk type-safe box Hive tetap perlu
   `build_runner` + `TypeAdapter`, yang justru menambah boilerplate.
