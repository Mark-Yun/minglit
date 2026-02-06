import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/config/iamport_config.dart';
import 'package:minglit_kit/src/features/iamport/logic/iamport_controller.dart';
import 'package:minglit_kit/src/features/iamport/logic/iamport_helper_web.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';

/// Web implementation of Iamport certification.
class MinglitIamportCertification extends ConsumerStatefulWidget {
  /// Creates a web certification widget.
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

  /// Creates the state for the web certification widget.
  @override
  ConsumerState<MinglitIamportCertification> createState() =>
      _MinglitIamportCertificationState();
}

class _MinglitIamportCertificationState
    extends ConsumerState<MinglitIamportCertification> {
  @override
  void initState() {
    super.initState();
    // Web: Trigger JS certification immediately after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startWebCertification());
    });
  }

  Future<void> _startWebCertification() async {
    final config = ref.read(iamportConfigProvider);
    final effectiveUserCode = widget.userCode ?? config.userCode;

    // Create data map manually without using portone_flutter package
    final data = {
      'merchant_uid':
          widget.merchantUid ?? 'mid_${DateTime.now().millisecondsSinceEpoch}',
      'name': widget.name,
      'phone': widget.phone,
      'carrier': widget.carrier,
      'company': widget.company ?? '밍글릿',
    };

    requestCertificationWeb(
      userCode: effectiveUserCode,
      data: data,
      onResult: (result) async {
        await _handleResult(result);
      },
    );
  }

  Future<void> _handleResult(Map<String, String> result) async {
    // Delegate to controller for verification/state update
    await ref
        .read(iamportControllerProvider.notifier)
        .onCertificationResult(result);

    final state = ref.read(iamportControllerProvider);

    if (state.hasValue && state.value != null && state.value!.success) {
      widget.onSuccess(state.value!.impUid!);
    } else if (state.hasError) {
      widget.onFail(state.error.toString());
    } else {
      widget.onFail(state.value?.errorMsg ?? '인증 취소 또는 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web: Render loading or empty (JS popup handles UI)
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MinglitCircularProgressIndicator(),
            SizedBox(height: 16),
            Text('본인인증 창을 띄우고 있습니다...'),
          ],
        ),
      ),
    );
  }
}
