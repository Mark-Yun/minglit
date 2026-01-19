import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:portone_flutter/portone_flutter.dart'; // TODO: Verify exact path
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
    
    // Example of how it should look once SDK is verified:
    /*
    const channelKey = 'channel-key-dc706c2c-ee6e-4efd-87c6-43729a69ea4a';
    const storeId = 'store-290628b6-7f96-455d-8856-ae4477d42d5c';
    try {
       // Open Portone SDK here
    } catch (e) {
       debugPrint('Error: $e');
    }
    */

    await Future.delayed(const Duration(seconds: 1));
    return 'mock_imp_uid_io';
  }
}