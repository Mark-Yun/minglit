import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import '../interface/identification_provider.dart';

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
    const storeId = 'MIIiasTest';
    const channelKey = 'channel-key-dc706c2c-ee6e-4efd-87c6-43729a69ea4a';

    // 1. Get Portone object from window (globalContext)
    final portone = globalContext['Portone'] ?? globalContext['PortOne'];

    if (portone == null) {
      debugPrint('⚠️ [IdentificationWeb] Portone JS SDK is not defined in window.');
      throw Exception('본인인증 모듈이 로드되지 않았습니다. 페이지를 새로고침 해주세요.');
    }

    try {
      final options = {
        'storeId': storeId,
        'channelKey': channelKey,
        'identityVerificationId': merchantUid,
        'customer': {
          'name': userName,
          'phoneNumber': userPhone,
        },
      }.jsify();

      // 2. Call requestIdentityVerification manually using callMethod
      // This bypasses static binding issues.
      final promise = (portone as JSObject).callMethod(
        'requestIdentityVerification'.toJS,
        options,
      ) as JSPromise;

      final result = await promise.toDart as PortoneWebResult;

      if (result.identityVerificationId != null) {
        return result.identityVerificationId;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [IdentificationWeb] Portone Request Error: $e');
      rethrow;
    }
  }
}

