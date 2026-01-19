import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import '../service/payment_service.dart';

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
      final res = result as Map;
      if (res['success'] == true) {
        completer.complete(res['imp_uid'] as String?);
      } else {
        completer.complete(null);
      }
    }.toJS;

    (imp).callMethod('request_pay'.toJS, options, callback);

    return completer.future;
  }
}
