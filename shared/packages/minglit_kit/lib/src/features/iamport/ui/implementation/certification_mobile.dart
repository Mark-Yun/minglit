import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MinglitIamportCertification extends ConsumerWidget {
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

  final String? userCode;
  final String? merchantUid;
  final String? name;
  final String? phone;
  final String? carrier;
  final String? company;
  final void Function(String impUid) onSuccess;
  final void Function(String errorMsg) onFail;

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