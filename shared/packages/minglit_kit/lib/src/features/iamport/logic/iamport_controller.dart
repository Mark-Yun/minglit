import 'package:flutter/widgets.dart';
import 'package:minglit_iamport_v1/minglit_iamport_v1.dart';
import 'package:minglit_kit/src/features/iamport/data/model/iamport_result_model.dart';
import 'package:minglit_kit/src/features/iamport/data/repository/iamport_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iamport_controller.g.dart';

@riverpod
class IamportController extends _$IamportController {
  @override
  AsyncValue<IamportResultModel?> build() {
    return const AsyncData(null);
  }

  Future<String?> startPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data,
  }) async {
    // 1. Invoke Payment via Service
    final impUid = await getPaymentService().requestPayment(
      context: context,
      userCode: userCode,
      data: data,
    );

    return impUid;
  }

  Future<void> onCertificationResult(Map<String, String> result) async {
    state = const AsyncLoading();

    try {
      final model = IamportResultModel.fromMap(result);

      if (model.success && model.impUid != null) {
        // 1. Server-side Verification
        await ref
            .read(iamportRepositoryProvider)
            .verifyCertification(model.impUid!);

        // 2. If successful, update state
        state = AsyncData(model);
      } else {
        // Failed from Iamport
        state = AsyncError(
          model.errorMsg ?? 'Unknown certification error',
          StackTrace.current,
        );
      }
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
