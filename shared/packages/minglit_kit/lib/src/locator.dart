import 'package:get_it/get_it.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/partner_repository.dart';
import 'package:minglit_kit/src/data/repositories/verification_repository.dart';

/// Global service locator instance.
final GetIt locator = GetIt.instance;

/// Initializes the service locator (call at app start).
void setupLocator({String? googleWebClientId, String? defaultRedirectUrl}) {
  locator
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        webClientId: googleWebClientId,
        defaultRedirectUrl: defaultRedirectUrl,
      ),
    )
    ..registerLazySingleton<VerificationRepository>(
      VerificationRepository.new,
    )
    ..registerLazySingleton<PartnerRepository>(
      PartnerRepository.new,
    );
}
