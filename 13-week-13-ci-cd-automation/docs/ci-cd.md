# Catatan CI/CD — Minggu 13

- **Workflow**: `.github/workflows/flutter-ci.yml`
- **Project yang dibangun**: `13-week-13-ci-cd-automation/`
- **Runner**: `ubuntu-latest`, Flutter `stable`, cache pub aktif

## 1. Rangkaian langkah

| # | Langkah | Perintah | Gagal berarti |
| --- | --- | --- | --- |
| 1 | Ambil kode | `actions/checkout@v4` | — |
| 2 | Siapkan Flutter | `subosito/flutter-action@v2` (`channel: stable`, `cache: true`) | Toolchain tidak siap |
| 3 | Catat toolchain | `flutter --version`, `java -version` | Berguna saat menyelidiki build gagal |
| 4 | Dependensi | `flutter pub get` | `pubspec.yaml` bermasalah |
| 5 | Format | `dart format --output=none --set-exit-if-changed .` | Ada berkas tidak terformat |
| 6 | Analisis | `flutter analyze --fatal-infos` | Ada error, warning, **atau info** |
| 7 | Test | `flutter test --coverage` | Ada test merah |
| 8 | Ringkasan coverage | `awk` membaca `coverage/lcov.info` | (tidak menggagalkan job) |
| 9 | Build APK | `flutter build apk --release` | Build Android rusak |
| 10 | Build AAB | `flutter build appbundle --release` | Build bundle rusak |
| 11 | Unggah artefak | `actions/upload-artifact@v4` (`android-builds`, 7 hari, `if-no-files-found: error`) | Artefak tidak terbentuk |

Langkah 9-11 hanya berjalan kalau langkah 5-7 lulus. Ini urutan yang penting:
jangan membuang waktu membangun APK dari kode yang sudah gagal test.

## 2. Kenapa bekerja di satu folder

Repo ini repo portofolio: root berisi folder minggu, bukan satu project Flutter.
Karena itu `defaults.run.working-directory` diarahkan ke
`13-week-13-ci-cd-automation`, dan langkah unggah artefak memakai path lengkap
dari root workspace (`13-week-13-ci-cd-automation/build/...`), sebab
`upload-artifact` tidak mengikuti `working-directory`.

Folder minggu 13 sengaja berisi project lengkap (termasuk `android/`) supaya
`flutter build` benar-benar bisa dijalankan. Folder minggu lain tetap ringkas
(hanya `lib/`, `test/`, `docs/`, `screenshots/`).

## 3. Pemicu dan izin

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:

permissions:
  contents: read
```

- `pull_request` memeriksa perubahan sebelum merge; `push` memeriksa branch utama.
- `develop` ditambahkan karena alur kerja repo ini memakai Git Flow (fitur →
  `develop` → `main`). Codelab memakai `main` saja; penyesuaian ini dicatat
  sebagai deviasi yang disengaja.
- `workflow_dispatch` untuk menjalankan ulang manual tanpa commit baru.
- `permissions: contents: read` adalah izin minimum: workflow hanya membaca kode,
  tidak menulis apa pun ke repo.
- `concurrency` dengan `cancel-in-progress: true` membatalkan run lama pada
  branch yang sama supaya tidak ada dua build berjalan untuk commit yang sudah
  usang.

## 4. Versioning

| Butir | Nilai |
| --- | --- |
| Versi sebelumnya | `1.0.0+1` |
| Versi di minggu ini | `1.1.0+2` |
| Tag | `v1.1.0` |

Alasan `1.1.0` (minor): minggu 11 mengubah perilaku daftar catatan (pagination)
dan menambah pemuatan bertahap, yang merupakan perubahan kompatibel yang terlihat
pengguna. Build number naik ke `2` karena artefak baru dihasilkan.

Aturan yang dipegang: `major` untuk perubahan tidak kompatibel, `minor` untuk
fitur kompatibel, `patch` untuk perbaikan, dan build number naik setiap unggahan.
Tag `v1.1.0` menunjuk commit yang sudah lolos pipeline.

## 5. Rahasia dan konfigurasi

| Hal | Perlakuan |
| --- | --- |
| API key provider AI | Tidak ada di repo. Disimpan di perangkat lewat `flutter_secure_storage`, diisi manual di halaman Pengaturan |
| Keystore produksi | Tidak ada di repo, dan tidak dipakai di workflow ini |
| `--dart-define` | Tidak dipakai untuk rahasia: nilai yang dikompilasi bisa diekstrak dari APK |
| Pull request dari fork | Tidak mendapat akses GitHub Secrets repository, jadi workflow ini tidak boleh bergantung pada secret |
| URL API | Konfigurasi publik, bukan credential |

Workflow ini tidak memakai `secrets:` sama sekali, sehingga aman dijalankan pada
PR (termasuk dari fork) tanpa membocorkan apa pun.

## 6. Risiko yang masih terbuka

| # | Risiko | Dampak | Rencana |
| --- | --- | --- | --- |
| R1 | APK/AAB ditandatangani debug key bawaan Flutter | Bisa diinstal untuk uji internal, **tidak layak Play Store** | Tambah workflow rilis terpisah dengan keystore dari Secrets, dibatasi ke tag |
| R2 | Workflow tidak mem-verifikasi tanda tangan artefak | Artefak bisa tertukar tanpa ketahuan | Simpan checksum SHA-256 di ringkasan run |
| R3 | Tidak ada `flutter analyze` untuk folder minggu lain | Kode laporan minggu lain bisa rusak tanpa terdeteksi | Matrix job per folder yang punya `pubspec.yaml` |
| R4 | Cache pub bisa basi setelah `pubspec.yaml` berubah | Build lambat, bukan salah | Kunci cache mengikuti hash `pubspec.lock` (sudah bawaan `flutter-action`) |
| R5 | Coverage tidak dipublikasikan ke layanan pihak ketiga | Tren coverage tidak terlihat | Cukup ringkasan di run summary untuk sekarang |
| R6 | Flutter 3.50 menandai `package:flutter/material.dart` deprecated (arahnya `package:material_ui`) | CI dengan `--fatal-infos` gagal di versi terbaru, padahal kode belum berubah | Workflow dipin ke 3.47.7; migrasi import direncanakan sebelum naik versi |
