import 'dart:async';
import 'package:flutter/material.dart';
// TODO: Verify exact V2 SDK import path
// import 'package:portone_flutter/portone_flutter.dart';
import '../interface/identification_provider.dart';

class IdentificationProviderImpl implements IdentificationProvider {
  @override
  Future<String?> verify({
    required BuildContext context,
    required String merchantUid,
    String? userPhone,
    String? userName,
  }) async {
    // For now, return a mock ID to avoid blocking development.
    // In real implementation, this will open the Portone V2 widget.
    debugPrint('IO Verification called for $userName');
    await Future.delayed(const Duration(seconds: 1));
    return 'mock_imp_uid_io';
  }
}
