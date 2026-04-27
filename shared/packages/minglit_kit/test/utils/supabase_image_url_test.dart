import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/supabase_image_url.dart';

void main() {
  group('supabaseImageUrl', () {
    const base = 'https://abc.supabase.co';

    test('비-Supabase URL → 변경 없음', () {
      const url = 'https://example.com/photo.jpg';
      expect(supabaseImageUrl(url, width: 400), url);
    });

    test('비-Supabase URL, width 없음 → 변경 없음', () {
      const url = 'https://cdn.example.com/img/foo.png';
      expect(supabaseImageUrl(url), url);
    });

    test('빈 문자열 → 빈 문자열 반환', () {
      expect(supabaseImageUrl('', width: 200), '');
    });

    test(
      'public-object URL + width → render/image 엔드포인트로 재작성 + width/quality 추가',
      () {
        const url = '$base/storage/v1/object/public/avatars/user123.jpg';
        final result = supabaseImageUrl(url, width: 400);

        expect(
          result,
          contains('/storage/v1/render/image/public/avatars/user123.jpg'),
        );
        expect(result, contains('width=400'));
        expect(result, contains('quality=70'));
        expect(result, isNot(contains('/storage/v1/object/public/')));
      },
    );

    test('public-object URL + width + 커스텀 quality → 반영됨', () {
      const url = '$base/storage/v1/object/public/covers/banner.jpg';
      final result = supabaseImageUrl(url, width: 800, quality: 85);

      expect(result, contains('/storage/v1/render/image/public/'));
      expect(result, contains('width=800'));
      expect(result, contains('quality=85'));
    });

    test('public-object URL, width 없음 → render/image로 재작성되지만 쿼리 없음', () {
      const url = '$base/storage/v1/object/public/images/foo.jpg';
      final result = supabaseImageUrl(url);

      // URL is rewritten to render path even without width (no-op but harmless).
      expect(
        result,
        contains('/storage/v1/render/image/public/images/foo.jpg'),
      );
      expect(result, isNot(contains('width=')));
      expect(result, isNot(contains('quality=')));
    });

    test('이미-render URL + width → 쿼리 병합', () {
      const url = '$base/storage/v1/render/image/public/avatars/user.jpg';
      final result = supabaseImageUrl(url, width: 200);

      expect(
        result,
        contains('/storage/v1/render/image/public/avatars/user.jpg'),
      );
      expect(result, contains('width=200'));
      expect(result, contains('quality=70'));
    });

    test('기존 쿼리 문자열 → 병합 (기존 키 보존)', () {
      const url =
          '$base/storage/v1/render/image/public/covers/event.jpg'
          '?token=xyz&format=webp';
      final result = supabaseImageUrl(url, width: 600);

      expect(result, contains('token=xyz'));
      expect(result, contains('format=webp'));
      expect(result, contains('width=600'));
      expect(result, contains('quality=70'));
    });

    test('기존 쿼리에 width 이미 있음 → 새 값으로 덮어씀', () {
      const url =
          '$base/storage/v1/render/image/public/photos/p.jpg'
          '?width=100&quality=50';
      final result = supabaseImageUrl(url, width: 300, quality: 80);

      expect(result, contains('width=300'));
      expect(result, contains('quality=80'));
      // Old values must not appear.
      expect(result, isNot(contains('width=100')));
      expect(result, isNot(contains('quality=50')));
    });
  });
}
