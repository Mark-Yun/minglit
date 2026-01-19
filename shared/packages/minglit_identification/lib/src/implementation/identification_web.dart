import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:web/web.dart' as web;
import '../interface/identification_provider.dart';

class IdentificationProviderImpl implements IdentificationProvider {
  @override
  Future<String?> verify({
    required BuildContext context,
    required String merchantUid,
    String? userPhone,
    String? userName,
  }) async {
    // TODO: Implement Web JS Interop for Portone V2
    print('Web Verification called. MerchantUID: $merchantUid');
    // Mock success for now
    await Future.delayed(const Duration(seconds: 1));
    return 'mock_imp_uid_web';
  }
}
