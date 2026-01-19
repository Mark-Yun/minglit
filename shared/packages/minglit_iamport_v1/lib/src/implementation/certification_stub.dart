import 'package:flutter/material.dart';
import '../service/certification_service.dart';

class CertificationServiceImpl implements CertificationService {
  @override
  Future<String?> verify({
    required BuildContext context,
    required String userCode,
    required String merchantUid,
    String? name,
    String? phone,
  }) {
    throw UnimplementedError();
  }
}
