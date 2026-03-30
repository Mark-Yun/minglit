import 'package:flutter/material.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:minglit_kit/src/utils/feedback_ext.dart';
import 'package:minglit_kit/src/utils/log.dart';

/// **Handle Minglit Error (UI)**
///
/// Standardized function to display error feedback to the user.
/// Call this from your UI layer (Screens/Widgets).
void handleMinglitError(
  BuildContext context,
  Object error, [
  StackTrace? st,
]) {
  // 1. Convert to MinglitException if not already
  final exception = MinglitException.from(error, st);

  // 2. Determine Message & Style
  String message;
  var isSystemError = false;

  if (exception is MinglitUserException) {
    message = exception.message;
  } else if (exception is MinglitAuthException) {
    message = exception.message;
  } else if (exception is MinglitSystemException) {
    message = exception.userMessage;
    isSystemError = true;
  } else {
    message = '알 수 없는 오류가 발생했습니다.';
    isSystemError = true;
  }

  // 3. Log System Errors
  if (isSystemError) {
    Log.e('❌ [ErrorUI] $message', error, st);
  } else {
    Log.d('ℹ️ [ErrorUI] User Feedback: $message');
  }

  // 4. Show Feedback using Standard System
  if (context.mounted) {
    if (isSystemError) {
      // Important errors get a Dialog
      // Use ignore to avoid awaiting in a sync void function
      // ignore: discarded_futures
      context.showMinglitAlert(
        title: '오류 발생',
        message: message,
      );
    } else {
      // Minor feedback gets a SnackBar
      context.showMinglitWarning(message);
    }
  }
}
