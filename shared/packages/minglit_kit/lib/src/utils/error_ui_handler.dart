import 'package:flutter/material.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
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

  // 4. Show Feedback (SnackBar)
  if (context.mounted) {
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSystemError 
            ? theme.colorScheme.error 
            : theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
