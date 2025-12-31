import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kakao_location_repository.g.dart';

@riverpod
KakaoLocationRepository kakaoLocationRepository(Ref ref) {
  return KakaoLocationRepository();
}

class KakaoLocationRepository {
  final Dio _dio = Dio();

  // Load from .env
  String get _restApiKey => dotenv.env['KAKAO_LOCAL_REST_API_KEY'] ?? '';

  Future<List<PartyLocation>> searchKeyword(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://dapi.kakao.com/v2/local/search/keyword.json',
        queryParameters: {'query': query},
        options: Options(
          headers: {'Authorization': 'KakaoAK $_restApiKey'},
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final documents = data['documents'] as List<dynamic>;
        return documents.map((doc) {
          final map = doc as Map<String, dynamic>;
          return PartyLocation(
            placeName: map['place_name'] as String,
            address: map['road_address_name'] as String? ??
                map['address_name'] as String,
            latitude: double.parse(map['y'] as String),
            longitude: double.parse(map['x'] as String),
          );
        }).toList();
      }
      return [];
    } on Exception catch (e) {
      Log.e('Kakao Search Error: $e');
      return [];
    }
  }
}
