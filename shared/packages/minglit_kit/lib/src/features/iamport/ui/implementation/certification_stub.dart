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
  // Stub implementation does not have logic in createState.
  ConsumerState<MinglitIamportCertification> createState() =>
      throw UnimplementedError('Iamport is not supported on this platform');
}

