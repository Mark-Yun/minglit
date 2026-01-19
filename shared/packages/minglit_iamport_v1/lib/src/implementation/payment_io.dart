import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';
import '../service/payment_service.dart';

class PaymentServiceImpl implements PaymentService {
  @override
  Future<String?> requestPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data,
  }) async {
    final completer = Completer<String?>();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IamportPayment(
          appBar: AppBar(title: const Text('결제')),
          userCode: userCode,
          data: PaymentData.fromJson(data),
          callback: (Map<String, String> result) {
            if (result['success'] == 'true' ||
                result['imp_success'] == 'true') {
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
