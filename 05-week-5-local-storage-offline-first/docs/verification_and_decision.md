# AI Verification Checklist & Keputusan Final

## Hasil verifikasi (dicatat sebelum menerima rekomendasi AI)

| Pertanyaan checklist | Jawaban | Tindakan |
| --- | --- | --- |
| Apakah AI menempatkan daftar catatan di SharedPreferences? | Tidak, AI memilih Hive | Diterima — SharedPreferences memang untuk preferensi kecil |
| Apakah skema AI mendukung antrean sync (dirty flag / updated_at)? | **Tidak.** Skema hanya title/body/updatedAt | **Ditolak** — ditambahkan kolom `dirty` pada tabel `notes` |
| Apakah klaim "real-time" didukung stream (Drift/watch) atau hanya asumsi? | Hanya asumsi; `watch()` tidak dijelaskan | **Dikoreksi** — reaktivitas real-time hanya via stream eksplisit (Drift `watch`), bukan otomatis |
| Apakah estimasi boilerplate AI masuk akal? | Tidak sepenuhnya; Hive tetap butuh TypeAdapter + build_runner | Dicatat; diverifikasi dengan `flutter pub add` |
| Keputusan final boleh berbeda dari AI? | Ya, kami memilih sqflite untuk catatan | Lihat di bawah |

## Tabel perbandingan final (keputusan kami)

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
| --- | --- | --- | --- | --- |
| Kompleksitas query | Hanya get/set key-value | Filter manual di Dart | SQL lengkap (WHERE, ORDER BY, JOIN) | SQL type-safe via Dart API |
| Kebutuhan relasi | Tidak mendukung | Tidak mendukung | Mendukung FOREIGN KEY | Mendukung relasi terdefinisi |
| Reaktivitas (stream) | Tidak | `box.watch()` (manual) | Tidak ada bawaan | `watch()` bawaan (unggul) |
| Type-safety | Primitif saja | Perlu TypeAdapter | Map<String, Object?> manual | Penuh, compile-time |
| Ukuran boilerplate | Sangat kecil | Sedang (adapter + build_runner) | Sedang (SQL string + mapping) | Besar (schema, dao, build_runner) |
| Kemudahan testing | Mudah (mock instance) | Perlu box testing | Bisa inject `openDb` / inMemory | Perlu setup database uji |
| Cocok untuk | Tema, last opened | Cache objek sederhana | Catatan, tugas, transaksi | Aplikasi besar, query kompleks |

## Rekomendasi final

| Kebutuhan | Pilihan final | Alasan |
| --- | --- | --- |
| Preferensi (tema, last opened) | **SharedPreferences** | Nilai primitif kecil, key-value, tanpa query; paling ringan dan mudah diuji |
| Catatan (CRUD + antrean sync) | **sqflite (SQLite)** | Mendukung `WHERE dirty = 1`, `ORDER BY updated_at`, dan kolom dirty flag untuk antrean sinkronisasi; repository bisa diuji dengan inject `openDb` |

Keputusan berbeda dari output AI awal (yang memilih Hive untuk catatan) karena
Hive tidak menyediakan query terstruktur untuk antrean sync tanpa memindai
seluruh box di Dart.

## Skema tabel untuk 1000+ catatan (final)

```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,          -- ISO8601, untuk last-write-wins
  dirty INTEGER NOT NULL DEFAULT 0   -- 1 = belum tersinkron
);
CREATE INDEX idx_notes_updated ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty);

CREATE TABLE cached_posts(
  id INTEGER PRIMARY KEY,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL
);
```

Aturan konflik yang didokumentasikan: **last-write-wins** berdasarkan
`updated_at`; catatan dengan `dirty = 1` dikirim lebih dulu saat online.
