import 'package:flutter/material.dart';
import 'package:minglit_iamport_v1/src/service/payment_service.dart';

class PaymentServiceImpl implements PaymentService {
  @override
  Future<String?> requestPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data,
  }) {
    throw UnimplementedError();
  }
}
