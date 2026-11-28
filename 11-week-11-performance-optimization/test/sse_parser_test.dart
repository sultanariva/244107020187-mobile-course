import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/assistant/data/sse_parser.dart';

void main() {
  const parser = SseParser();

  test('mengambil potongan teks dari baris data [OI]-compatible', () {
    const line = 'data: {"id":"x","choices":[{"delta":{"content":"Halo"}}]}';
    expect(parser.parseLine(line), 'Halo');
  });

  test('mengabaikan penanda [DONE]', () {
    expect(parser.parseLine('data: [DONE]'), isNull);
  });

  test('mengabaikan baris kosong dan komentar SSE', () {
    expect(parser.parseLine(''), isNull);
    expect(parser.parseLine(': ping'), isNull);
    expect(parser.parseLine('event: message'), isNull);
  });

  test('mengabaikan delta tanpa content (mis. hanya role)', () {
    const line = 'data: {"choices":[{"delta":{"role":"assistant"}}]}';
    expect(parser.parseLine(line), isNull);
  });

  test('mengembalikan null untuk JSON rusak, bukan melempar', () {
    expect(parser.parseLine('data: {bukan json}'), isNull);
    expect(parser.parseLine('data: {"choices":[]}'), isNull);
  });
}
