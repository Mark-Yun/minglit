import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iamport_config.g.dart';

/// Configuration for PortOne (Iamport) integration.
class IamportConfig {
  /// Creates an [IamportConfig] with a user code.
  const IamportConfig({
    required this.userCode,
  });

  /// PortOne user code used for payment flows.
  final String userCode;
}

/// Provides the current [IamportConfig].
@Riverpod(keepAlive: true)
IamportConfig iamportConfig(Ref ref) {
  // PortOne Test User Code: imp10391932
  const userCode = String.fromEnvironment(
    'IAMPORT_USER_CODE',
    defaultValue: 'imp10391932',
  );

  return const IamportConfig(userCode: userCode);
}
