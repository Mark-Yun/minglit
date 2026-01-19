import 'package:flutter/material.dart';

abstract class CertificationService {
  /// Initiates Iamport V1 Identity Verification.
  /// Returns imp_uid if successful, null otherwise.
  Future<String?> verify({
    required BuildContext context,
    required String userCode,
    required String merchantUid,
    String? name,
    String? phone,
  });
}
