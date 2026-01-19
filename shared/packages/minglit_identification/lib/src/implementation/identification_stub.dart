import 'package:flutter/material.dart';
import '../interface/identification_provider.dart';

class IdentificationProviderImpl implements IdentificationProvider {
  @override
  Future<String?> verify({
    required BuildContext context,
    required String merchantUid,
    String? userPhone,
    String? userName,
  }) async {
    throw UnimplementedError(
        'Identity verification not implemented for this platform.');
  }
}
