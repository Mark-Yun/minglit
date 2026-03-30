import 'dart:convert';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checkin_controller.g.dart';

enum CheckinResult {
  idle,
  processing,
  success,
  alreadyCheckedIn,
  invalid,
  error,
}

class CheckinState {
  const CheckinState({
    required this.result,
    this.message,
    this.userName,
  });

  final CheckinResult result;
  final String? message;
  final String? userName;

  CheckinState copyWith({
    CheckinResult? result,
    String? message,
    String? userName,
  }) {
    return CheckinState(
      result: result ?? this.result,
      message: message ?? this.message,
      userName: userName ?? this.userName,
    );
  }
}

@riverpod
class CheckinController extends _$CheckinController {
  @override
  CheckinState build() {
    return const CheckinState(result: CheckinResult.idle);
  }

  Future<void> processQR(String rawData) async {
    if (state.result == CheckinResult.processing) return;

    state = state.copyWith(result: CheckinResult.processing);

    try {
      // 1. Parse JSON
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final token = TicketToken.fromJson(json);

      // 2. Verify with Repository
      final repo = ref.read(checkinRepositoryProvider);

      // Fix #458: 서버 공개키를 fetch하여 검증 — 임시 키페어 생성 제거
      final serverPublicKey = await repo.fetchServerPublicKey();
      final success = await repo.verifyAndCheckin(
        token: token,
        serverPublicKey: serverPublicKey,
      );

      if (success) {
        state = state.copyWith(
          result: CheckinResult.success,
          userName: 'User ${token.userId.substring(0, 4)}', // Simulated name
        );
      } else {
        state = state.copyWith(
          result: CheckinResult.invalid,
          message: '유효하지 않은 티켓입니다.',
        );
      }
    } on Object catch (e) {
      Log.e('Check-in processing failed', e);
      state = state.copyWith(
        result: CheckinResult.invalid,
        message: '티켓 데이터를 읽을 수 없습니다.',
      );
    }

    // Reset to idle after a delay to allow for feedback UI
    await Future<void>.delayed(const Duration(seconds: 3));
    state = const CheckinState(result: CheckinResult.idle);
  }
}
