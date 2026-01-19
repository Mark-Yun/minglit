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
    try {
      final customer = <String, dynamic>{};
      if (userName != null && userName.isNotEmpty) customer['name'] = userName;
      if (userPhone != null && userPhone.isNotEmpty) customer['phoneNumber'] = userPhone;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PortoneCheck(
            storeId: storeId,
            channelKey: channelKey,
            paymentId: merchantUid,
            customer: customer.isEmpty ? null : customer,
            onResult: (result) {

  }
}
