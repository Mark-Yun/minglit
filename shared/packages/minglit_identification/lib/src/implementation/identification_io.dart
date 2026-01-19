import 'dart:async';
import 'package:flutter/material.dart';
// ignore: uri_does_not_exist
import 'package:portone_flutter/iamport_certification.dart'; 
import 'package:portone_flutter/model/certification_data.dart';
import '../interface/identification_provider.dart';

class IdentificationProviderImpl implements IdentificationProvider {
  @override
  Future<String?> verify({
    required BuildContext context,
    required String merchantUid,
    String? userPhone,
    String? userName,
  }) async {
    final completer = Completer<String?>();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IamportCertification(
          appBar: AppBar(title: const Text('본인인증')),
          // TODO: Get userCode from config or env
          userCode: 'imp10391932', // Example Code
          data: CertificationData(
            merchantUid: merchantUid,
            name: userName,
            phone: userPhone,
          ),
          callback: (Map<String, String> result) {
            if (result['success'] == 'true') {
              completer.complete(result['imp_uid']);
            } else {
              completer.complete(null);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );

    return completer.future;
  }
}
