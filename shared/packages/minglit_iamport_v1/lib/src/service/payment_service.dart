import 'package:flutter/material.dart';

// ignore: one_member_abstracts -- Service interface with single method is intentional for dependency injection
abstract class PaymentService {
  /// Initiates Iamport V1 Payment.
  /// Returns imp_uid if successful, null otherwise.
  Future<String?> requestPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data, // Iamport Payment Data
  });
}
