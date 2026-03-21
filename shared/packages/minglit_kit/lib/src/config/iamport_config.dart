import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iamport_config.g.dart';

/// Configuration for PortOne (Iamport) integration.
class IamportConfig {
  /// Creates an [IamportConfig] with a user code.
  const IamportConfig({
    required this.userCode,
    this.mobileRedirectUrl,
  });

  /// PortOne user code used for payment flows.
  final String userCode;

  /// Mobile redirect URL for Iamport certification cancel flow.
  final String? mobileRedirectUrl;
}

/// Provides the current [IamportConfig].
@Riverpod(keepAlive: true)
IamportConfig iamportConfig(Ref ref) {
  // PortOne Test User Code: imp10391932
  const userCode = String.fromEnvironment(
    'IAMPORT_USER_CODE',
    defaultValue: 'imp10391932',
  );
  const mobileRedirectScheme = String.fromEnvironment(
    'MOBILE_REDIRECT_SCHEME',
  );

  return IamportConfig(
    userCode: userCode,
    mobileRedirectUrl: mobileRedirectScheme.isEmpty
        ? null
        : '$mobileRedirectScheme://iamport',
  );
}
