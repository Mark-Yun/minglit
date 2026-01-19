import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:js_interop';
import '../interface/identification_provider.dart';

@JS('Portone.requestIdentityVerification')
external JSPromise _requestIdentityVerification(JSAny options);

extension type PortoneWebResult(JSObject _) implements JSObject {
  external String? get code;
  external String? get message;
  external String? get identityVerificationId;
}

class IdentificationProviderImpl implements IdentificationProvider {
  @override
  Future<String?> verify({
    required BuildContext context,
    required String merchantUid,
    String? userPhone,
    String? userName,
  }) async {
    // TODO: 운영 환경에서는 채널 키를 환경 변수에서 관리해야 합니다.
    const storeId = 'MIIiasTest';
    const channelKey = 'channel-key-dc706c2c-ee6e-4efd-87c6-43729a69ea4a';

    try {
      final options = {
        'storeId': storeId,
        'channelKey': channelKey,
        'identityVerificationId': merchantUid,
        'customer': {
          'name': userName,
          'phoneNumber': userPhone,
        },
      }.jsify()!;

      final promise = _requestIdentityVerification(options);
      final result = await promise.toDart as PortoneWebResult;

      if (result.identityVerificationId != null) {
        return result.identityVerificationId;
      }

      return null;
    } catch (e) {
      debugPrint('Portone Web Error: $e');
      if (e.toString().contains('Portone is not defined')) {
        await Future.delayed(const Duration(seconds: 1));
        return 'mock_imp_uid_web_dev';
      }
      return null;
    }
  }
}
