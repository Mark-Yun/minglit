import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/test_utils.dart';

void main() {
  group('CheckinController', () {
    test('initial state is idle with no message or userName', () {
      final container = createContainer();
      final state = container.read(checkinControllerProvider);

      expect(state.result, CheckinResult.idle);
      expect(state.message, isNull);
      expect(state.userName, isNull);
    });

    test('CheckinState copyWith updates individual fields', () {
      const original = CheckinState(result: CheckinResult.idle);

      final updated = original.copyWith(
        result: CheckinResult.success,
        userName: 'User 1234',
      );

      expect(updated.result, CheckinResult.success);
      expect(updated.userName, 'User 1234');
      expect(updated.message, isNull);
    });

    test('CheckinState copyWith preserves unchanged fields', () {
      const original = CheckinState(
        result: CheckinResult.invalid,
        message: '유효하지 않은 티켓입니다.',
      );

      final updated = original.copyWith(result: CheckinResult.idle);

      expect(updated.result, CheckinResult.idle);
      expect(updated.message, '유효하지 않은 티켓입니다.');
    });

    test('CheckinState copyWith without args returns same values', () {
      const original = CheckinState(
        result: CheckinResult.error,
        message: 'err',
        userName: 'John',
      );

      final copy = original.copyWith();

      expect(copy.result, CheckinResult.error);
      expect(copy.message, 'err');
      expect(copy.userName, 'John');
    });

    test('CheckinResult enum has all expected values', () {
      expect(
        CheckinResult.values,
        containsAll([
          CheckinResult.idle,
          CheckinResult.processing,
          CheckinResult.success,
          CheckinResult.alreadyCheckedIn,
          CheckinResult.invalid,
          CheckinResult.error,
        ]),
      );
    });
  });
}
