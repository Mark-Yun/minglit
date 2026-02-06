import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

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
    final imp = globalContext['IMP'];
    if (imp == null) throw Exception('Iamport SDK (IMP) not loaded.');

    (imp as JSObject).callMethod('init'.toJS, userCode.toJS);

    final completer = Completer<String?>();

    final options = {
      'merchant_uid': merchantUid,
      'name': name,
      'phone': phone,
    }.jsify();

        final callback = (JSObject result) {

          // Use getProperty to access JS object fields safely

          final success = result.getProperty('success'.toJS);

          final impUid = result.getProperty('imp_uid'.toJS);

          final errorMsg = result.getProperty('error_msg'.toJS);

    

          // success can be boolean or string 'true' depending on SDK version

          final isSuccess = success == true.toJS || success.toString() == 'true';

    

          if (isSuccess) {

            completer.complete(impUid?.toString());

          } else {

            debugPrint('Certification Failed: $errorMsg');

            completer.complete(null);

          }

        }.toJS;

    imp.callMethod('certification'.toJS, options, callback);

    return completer.future;
  }
}
