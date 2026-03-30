import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/utils/error_ui_handler.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';

/// Extensions for Riverpod's AsyncValue to handle Minglit specific errors.
extension AsyncValueMinglitX<T> on AsyncValue<T> {
  /// Wraps a [Future] and converts any thrown error into a [MinglitException].
  /// This ensures that the UI layer always receives a standardized exception.
  static Future<AsyncValue<T>> guardMinglit<T>(
    Future<T> Function() future,
  ) async {
    try {
      return AsyncValue.data(await future());
    } on Object catch (err, stack) {
      return AsyncValue.error(MinglitException.from(err, stack), stack);
    }
  }

  /// Use this inside `ref.listen` to automatically show error feedback.
  ///
  /// Example:
  /// ```dart
  /// ref.listen(myProvider, (_, next) {
  ///   next.showMinglitError(context);
  /// });
  /// ```
  void showMinglitError(BuildContext context) {
    // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
    final err = error;
    if (!isLoading && hasError && err != null) {
      handleMinglitError(context, err, stackTrace);
    }
  }
}
