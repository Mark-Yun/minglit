import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  /// 서버 응답 오류 (DB, Edge Functions 등)
  const factory Failure.server({required String message}) = _ServerFailure;

  /// 네트워크 연결 오류 (인터넷 미연결 등)
  const factory Failure.network({@Default('네트워크 연결을 확인해 주세요.') String message}) =
      _NetworkFailure;

  /// 인증 관련 오류 (로그인 실패, 세션 만료 등)
  const factory Failure.auth({required String message}) = _AuthFailure;

  /// 데이터 유효성 검사 오류
  const factory Failure.validation({required String message}) = _ValidationFailure;

  /// 알 수 없는 오류
  const factory Failure.unknown({@Default('알 수 없는 오류가 발생했습니다.') String message}) =
      _UnknownFailure;
}
