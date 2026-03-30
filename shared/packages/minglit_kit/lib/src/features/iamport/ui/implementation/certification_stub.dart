import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform stub for Iamport certification (unsupported platforms).
class MinglitIamportCertification extends ConsumerStatefulWidget {
  /// Creates a stub certification widget.
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

  /// Creates the state for the stub certification widget.
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
