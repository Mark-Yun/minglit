import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';
import 'package:minglit_iamport_v1/src/service/payment_service.dart';

class PaymentServiceImpl implements PaymentService {
  @override
  Future<String?> requestPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data,
  }) async {
    final completer = Completer<String?>();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageContext) => buildPaymentPage(
          userCode: userCode,
          data: data,
          onResult: (Map<String, String> result) {
            if (result['success'] == 'true' ||
                result['imp_success'] == 'true') {
              completer.complete(result['imp_uid']);
            } else {
              completer.complete(null);
            }
            Navigator.pop(pageContext);
          },
        ),
      ),
    );

    // Fix #1535: 사용자가 네이티브 뒤로가기 버튼으로 결제 웹뷰를 이탈하면
    // callback이 호출되지 않아 Completer가 영구히 pending 상태로 남는다.
    // Navigator.push()가 반환된 후에도 미완료 상태면 null로 완료해 취소 처리.
    if (!completer.isCompleted) {
      completer.complete(null);
    }

    return completer.future;
  }

  @visibleForTesting
  Widget buildPaymentPage({
    required String userCode,
    required Map<String, dynamic> data,
    required void Function(Map<String, String> result) onResult,
  }) {
    return IamportPayment(
      appBar: AppBar(title: const Text('결제')),
      userCode: userCode,
      // Fix #1503: iamport_flutter-0.10.21 generated code does
      // `json['display'] as Map<String, dynamic>` without null guard —
      // crashes when caller omits the 'display' key.  Provide an empty
      // map so the cast succeeds and cardQuota defaults to [].
      data: PaymentData.fromJson({
        'display': <String, dynamic>{},
        ...data,
      }),
      callback: onResult,
    );
  }
}
