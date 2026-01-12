import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamport_flutter/iamport_certification.dart';
import 'package:iamport_flutter/model/certification_data.dart';
import 'package:minglit_kit/src/config/iamport_config.dart';
import 'package:minglit_kit/src/features/iamport/logic/iamport_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

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

  /// Iamport Shop User Code (가맹점 식별코드)
  /// If null, uses IAMPORT_USER_CODE from environment variables.
  final String? userCode;

  /// Unique Merchant UID (Optional: auto-generated if null)
  final String? merchantUid;

  /// Pre-filled Name
  final String? name;

  /// Pre-filled Phone
  final String? phone;

  /// Carrier (SKT, KT, LGT, MVNO)
  final String? carrier;

  /// Company Name displayed on Certification
  final String? company;

  /// Callback on success (returns imp_uid)
  final void Function(String impUid) onSuccess;

  /// Callback on failure
  final void Function(String errorMsg) onFail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(iamportConfigProvider);
    final effectiveUserCode = userCode ?? config.userCode;

    return IamportCertification(
      appBar: AppBar(
        title: const Text('본인인증'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      initialChild: const ColoredBox(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: MinglitColors.primary,
              ),
              SizedBox(height: 16),
              Text('인증 페이지로 이동 중입니다...'),
            ],
          ),
        ),
      ),
      userCode: effectiveUserCode,
      data: CertificationData(
        merchantUid:
            merchantUid ?? 'mid_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
        carrier: carrier,
        company: company ?? '밍글릿',
      ),
      callback: (Map<String, String> result) async {
        // Delegate to controller for verification/state update
        await ref
            .read(iamportControllerProvider.notifier)
            .onCertificationResult(result);

        final state = ref.read(iamportControllerProvider);

        if (state.hasValue && state.value != null && state.value!.success) {
          onSuccess(state.value!.impUid!);
        } else if (state.hasError) {
          onFail(state.error.toString());
        } else {
          onFail(state.value?.errorMsg ?? '인증 취소 또는 실패');
        }
      },
    );
  }
}
