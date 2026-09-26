import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week3_todo/providers/stats_provider.dart';
import 'package:week3_todo/providers/todo_provider.dart';

void main() {
  group('RingkasanStatistikNotifier', () {
    test('menghasilkan 3 item ringkasan saat tugas tersedia', () async {
      // Saya mematikan simulasi error agar data yang dihasilkan tetap stabil dan
      // fokus pengujian hanya pada logika perhitungan statistik.
      RingkasanStatistikNotifier.enableFailureSimulation = false;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final todoNotifier = container.read(todoListProvider.notifier);
      todoNotifier.add('Kerjakan PR minggu 3');
      todoNotifier.add('Review materi');
      todoNotifier.toggle(0);

      final hasil = await container.read(ringkasanStatistikProvider.future);

      expect(hasil, const [
        'Total Tugas: 2 Item',
        'Tugas Selesai: 1 Item',
        'Tugas Belum Selesai: 1 Item',
      ]);
    });

    test('mengembalikan daftar kosong saat belum ada tugas', () async {
      // Kondisi kosong tetap aman karena halaman statistik bisa menampilkan pesan
      // yang lebih jelas tanpa ada data yang tidak valid.
      RingkasanStatistikNotifier.enableFailureSimulation = false;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final hasil = await container.read(ringkasanStatistikProvider.future);

      expect(hasil, isEmpty);
    });
  });
}
