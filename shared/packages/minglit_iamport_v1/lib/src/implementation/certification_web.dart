import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import '../service/certification_service.dart';

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
      final res =
          result as Map; // Simplification, in real use we check properties
      if (res['success'] == true) {
        completer.complete(res['imp_uid'] as String?);
      } else {
        completer.complete(null);
      }
    }.toJS;

    (imp).callMethod('certification'.toJS, options, callback);

    return completer.future;
  }
}
