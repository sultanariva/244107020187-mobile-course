import 'package:integration_test/integration_test_driver.dart';

/// Driver untuk `flutter drive` pada pengukuran performa Minggu 11.
///
/// Hasil `watchPerformance` ditulis ke `integration_response_data.json`
/// (berisi ringkasan frame build/raster, termasuk jumlah frame yang melewati
/// budget 16 ms).
Future<void> main() => integrationDriver();
