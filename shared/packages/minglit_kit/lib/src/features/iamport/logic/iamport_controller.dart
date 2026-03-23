import 'package:flutter/widgets.dart';
import 'package:minglit_iamport_v1/minglit_iamport_v1.dart';
import 'package:minglit_kit/src/features/iamport/data/model/iamport_result_model.dart';
import 'package:minglit_kit/src/features/iamport/data/repository/iamport_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iamport_controller.g.dart';

/// Controls Iamport payment and certification state.
@riverpod
class IamportController extends _$IamportController {
  /// Initializes the controller state.
  @override
  AsyncValue<IamportResultModel?> build() {
    return const AsyncData(null);
  }

  /// Starts a payment flow and returns the Iamport UID.
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

  /// Handles certification callback [result] and updates state.
  Future<void> onCertificationResult(Map<String, String> result) async {
    state = const AsyncLoading();

    try {
      final model = IamportResultModel.fromMap(result);

      // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
      final impUid = model.impUid;
      if (model.success && impUid != null) {
        // 1. Server-side Verification
        await ref
            .read(iamportRepositoryProvider)
            .verifyCertification(impUid);

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

  /// Resets the controller state to its initial value.
  void reset() {
    state = const AsyncData(null);
  }
}
