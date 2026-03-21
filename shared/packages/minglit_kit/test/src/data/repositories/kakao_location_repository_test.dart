import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/kakao_location_repository.dart';

void main() {
  late KakaoLocationRepository repository;

  setUp(() {
    repository = KakaoLocationRepository();
  });

  group('KakaoLocationRepository', () {
    group('searchKeyword', () {
      test('returns empty list for empty query', () async {
        final result = await repository.searchKeyword('');
        expect(result, isEmpty);
      });

      test('returns empty list when API key is not defined', () async {
        // KAKAO_LOCAL_REST_API_KEY is not set in test environment,
        // so this should return empty list gracefully.
        final result = await repository.searchKeyword('강남역');
        expect(result, isEmpty);
      });
    });
  });
}
