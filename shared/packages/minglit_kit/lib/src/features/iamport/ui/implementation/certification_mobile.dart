import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile placeholder for Iamport certification UI.
class MinglitIamportCertification extends ConsumerWidget {
  /// Creates a mobile certification screen.
  const MinglitIamportCertification({
    required this.onSuccess,
    required this.onFail,
    super.key,
    this.userCode,
    this.merchantUid,
    this.name,
    this.phone,
    this.carrier,
    this.company,
  });

  /// The Iamport user code for certification.
  final String? userCode;

  /// Optional merchant UID for the request.
  final String? merchantUid;

  /// Optional user name for the request.
  final String? name;

  /// Optional phone number for the request.
  final String? phone;

  /// Optional carrier for the request.
  final String? carrier;

  /// Optional company name for the request.
  final String? company;

  /// Callback invoked with the imp_uid on success.
  final void Function(String impUid) onSuccess;

  /// Callback invoked with an error message on failure.
  final void Function(String errorMsg) onFail;

  /// Builds the mobile certification placeholder UI.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('본인인증')),
      body: const Center(
        child: Text('본인인증 기능은 현재 준비 중입니다.'),
      ),
    );
  }
}
