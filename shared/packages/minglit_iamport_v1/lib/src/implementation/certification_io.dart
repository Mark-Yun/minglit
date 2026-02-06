import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iamport_flutter/Iamport_certification.dart';
import 'package:iamport_flutter/model/certification_data.dart';
import 'package:minglit_iamport_v1/src/service/certification_service.dart';

class CertificationServiceImpl implements CertificationService {
  @override
  Future<String?> verify({
    required BuildContext context,
    required String userCode,
    required String merchantUid,
    String? name,
    String? phone,
  }) async {
    final completer = Completer<String?>();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IamportCertification(
          appBar: AppBar(title: const Text('본인인증')),
          userCode: userCode,
          data: CertificationData(
            merchantUid: merchantUid,
            name: name,
            phone: phone,
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
