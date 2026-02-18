import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

import 'package:minglit_iamport_v1/src/service/payment_service.dart';

class PaymentServiceImpl implements PaymentService {
  @override
  Future<String?> requestPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data,
  }) async {
    final imp = globalContext['IMP'];
    if (imp == null) throw Exception('Iamport SDK (IMP) not loaded.');

    (imp as JSObject).callMethod('init'.toJS, userCode.toJS);

    final completer = Completer<String?>();

    final options = data.jsify();

    final callback = (JSObject result) {
      final success = result.getProperty('success'.toJS);
      final impUid = result.getProperty('imp_uid'.toJS);
      final errorMsg = result.getProperty('error_msg'.toJS);

      // success can be boolean or string 'true' depending on SDK version
      final isSuccess = success == true.toJS || success.toString() == 'true';

      if (isSuccess) {
        completer.complete(impUid?.toString());
      } else {
        debugPrint('Payment Failed: $errorMsg');
        completer.complete(null);
      }
    }.toJS;

    imp.callMethod('request_pay'.toJS, options, callback);

    return completer.future;
  }
}
