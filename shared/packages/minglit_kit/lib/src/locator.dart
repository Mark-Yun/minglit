import 'package:get_it/get_it.dart';
import 'auth/auth_service.dart';
import 'auth/verification_service.dart';

final GetIt locator = GetIt.instance;

/// 서비스 로케이터 초기화 (앱 시작 시 호출)
void setupLocator({String? googleWebClientId}) {
  // AuthService를 싱글톤으로 등록
  locator.registerLazySingleton<AuthService>(
    () => AuthService(webClientId: googleWebClientId),
  );

  // VerificationService를 싱글톤으로 등록
  locator.registerLazySingleton<VerificationService>(
    () => VerificationService(),
  );
}
