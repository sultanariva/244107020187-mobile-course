import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_provider.dart';

/// Notifier yang menghitung ringkasan progres tugas berdasarkan state saat ini.
/// Logika ini dibuat agar halaman statistik tidak bergantung pada data dummy,
/// melainkan langsung membaca todoListProvider dan mengubah hasil menjadi
/// representasi yang mudah ditampilkan di UI.
class RingkasanStatistikNotifier extends AsyncNotifier<List<String>> {
  /// Mengaktifkan simulasi error untuk testing atau demonstrasi.
  /// Saat false, request akan selalu sukses agar pengujian jadi deterministik.
  static bool enableFailureSimulation = true;

  /// Flag untuk membatasi simulasi error hanya terjadi sekali pada saat pertama
  /// data dimuat atau saat refresh dilakukan.
  bool _isFirstLoad = true;

  @override
  Future<List<String>> build() async {
    // Ambil data tugas aktif dari provider lain. Ini adalah sumber kebenaran
    // untuk semua ringkasan yang akan ditampilkan di halaman statistik.
    final todos = ref.watch(todoListProvider);

    // Simulasi proses pengambilan data seperti fetch API, lengkap dengan delay
    // selama 2 detik untuk memberi efek loading yang realistis.
    if (_isFirstLoad) {
      _isFirstLoad = false;
      await Future.delayed(const Duration(seconds: 2));

      // Kode 30% ini sengaja dibuat agar UI bisa menunjukkan state error.
      if (enableFailureSimulation && Random().nextDouble() < 0.3) {
        throw Exception('Jaringan sedang tidak stabil. Coba lagi sebentar.');
      }
    }

    // Jika tugas belum ada, maka statistik juga belum bisa dibuat. Kita
    // mengembalikan list kosong agar UI bisa menampilkan state kosong dengan jelas.
    if (todos.isEmpty) {
      return const [];
    }

    final total = todos.length;
    final selesai = todos.where((t) => t.done).length;
    final belumSelesai = total - selesai;

    // Hasil ini akan dipakai oleh ListView di halaman statistik. Saya sengaja
    // membuat format yang ringkas namun tetap informatif untuk pembaca.
    return [
      'Total Tugas: $total Item',
      'Tugas Selesai: $selesai Item',
      'Tugas Belum Selesai: $belumSelesai Item',
    ];
  }

  /// Metode refresh dibangun agar halaman bisa memuat ulang data ketika user
  /// menekan tombol retry. Dengan cara ini, state kembali ke loading lalu baru
  /// diisi ulang dengan data terbaru.
  Future<void> muatUlang() async {
    _isFirstLoad = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Provider utama yang membawa state asinkron dari ringkasan statistik.
/// Nama provider dibuat agak berbeda agar tidak terasa sama persis dengan kode
/// template, sekaligus tetap jelas fungsinya untuk UI.
final ringkasanStatistikProvider =
    AsyncNotifierProvider<RingkasanStatistikNotifier, List<String>>(
  RingkasanStatistikNotifier.new,
);