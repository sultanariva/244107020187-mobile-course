import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/posts/data/models/post_model.dart';
import 'package:week5_offline_notes/features/posts/domain/entities/post.dart';

void main() {
  group('PostModel mapping', () {
    test('fromJson membaca id, title, dan body', () {
      final model = PostModel.fromJson({
        'id': 7,
        'title': 'Judul',
        'body': 'Isi',
      });

      expect(model.id, 7);
      expect(model.title, 'Judul');
      expect(model.body, 'Isi');
    });

    test('fromJson memberi nilai default saat title/body hilang', () {
      final model = PostModel.fromJson({'id': 3});

      expect(model.id, 3);
      expect(model.title, '');
      expect(model.body, '');
    });

    test('toJson dan fromJson konsisten (round-trip)', () {
      const original = PostModel(id: 11, title: 'A', body: 'B');
      final restored = PostModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
    });

    test('toEntity menghasilkan entity murni tanpa method mapping', () {
      const model = PostModel(id: 1, title: 'T', body: 'B');

      final Post entity = model.toEntity();

      expect(entity.id, 1);
      expect(entity.title, 'T');
      expect(entity.body, 'B');
    });
  });

  group('Payload cache', () {
    test('listToPayload dan listFromPayload konsisten', () {
      const posts = [
        Post(id: 1, title: 'Satu', body: 'a'),
        Post(id: 2, title: 'Dua', body: 'b'),
      ];

      final payload = PostModel.listToPayload(posts);
      final restored = PostModel.listFromPayload(payload);

      expect(restored, hasLength(2));
      expect(restored.first.title, 'Satu');
      expect(restored.last.body, 'b');
    });

    test('payload rusak melempar FormatException (ditangani repository)', () {
      expect(
        () => PostModel.listFromPayload('{bukan json}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
