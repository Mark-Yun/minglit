import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MinglitIamportCertification extends ConsumerStatefulWidget {
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
  ConsumerState<MinglitIamportCertification> createState() =>
      _MinglitIamportCertificationState();
}

class _MinglitIamportCertificationState
    extends ConsumerState<MinglitIamportCertification> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Iamport is not supported on this platform');
  }
}
