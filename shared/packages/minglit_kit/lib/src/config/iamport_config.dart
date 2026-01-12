import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iamport_config.g.dart';

class IamportConfig {
  const IamportConfig({
    required this.userCode,
  });

  final String userCode;
}

@Riverpod(keepAlive: true)
IamportConfig iamportConfig(Ref ref) {
  // PortOne Test User Code: imp10391932
  const userCode = String.fromEnvironment(
    'IAMPORT_USER_CODE',
    defaultValue: 'imp10391932',
  );

  return const IamportConfig(userCode: userCode);
}
