import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/config/iamport_config.dart';
import 'package:minglit_kit/src/features/iamport/logic/iamport_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:portone_flutter/iamport_certification.dart';
import 'package:portone_flutter/model/certification_data.dart';

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
    final theme = Theme.of(context);
    // Native: Render Iamport WebView
    final config = ref.watch(iamportConfigProvider);
    final effectiveUserCode = widget.userCode ?? config.userCode;

    return IamportCertification(
      appBar: AppBar(
        title: const Text('본인인증'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      initialChild: ColoredBox(
        color: theme.colorScheme.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MinglitCircularProgressIndicator(
              color: MinglitColors.primary,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '인증 페이지로 이동 중입니다...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      userCode: effectiveUserCode,
      data: CertificationData(
        merchantUid:
            widget.merchantUid ??
            'mid_${DateTime.now().millisecondsSinceEpoch}',
        name: widget.name,
        phone: widget.phone,
        carrier: widget.carrier,
        company: widget.company ?? '밍글릿',
      ),
      callback: _handleResult,
    );
  }
}
