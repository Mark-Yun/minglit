import 'package:get_it/get_it.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/partner_repository.dart';
import 'data/repositories/verification_repository.dart';

final GetIt locator = GetIt.instance;

/// 서비스 로케이터 초기화 (앱 시작 시 호출)
void setupLocator({String? googleWebClientId, String? defaultRedirectUrl}) {
  // AuthRepository를 싱글톤으로 등록
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      webClientId: googleWebClientId,
      defaultRedirectUrl: defaultRedirectUrl,
    ),
  );

  // VerificationRepository를 싱글톤으로 등록
  locator.registerLazySingleton<VerificationRepository>(
    () => VerificationRepository(),
  );

  // PartnerRepository를 싱글톤으로 등록
  locator.registerLazySingleton<PartnerRepository>(
    () => PartnerRepository(),
  );
}
