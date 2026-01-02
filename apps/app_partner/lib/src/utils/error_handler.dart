import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Handles exceptions and displays appropriate user feedback via SnackBar.
/// Logs system errors for debugging.
void handleMinglitError(
  BuildContext context,
  Object error, [
  StackTrace? st,
]) {
  if (error is MinglitUserException) {
    // User-facing error: Show message directly, no logging needed
    // (or Info level)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  } else if (error is MinglitSystemException) {
    // System error: Log it and show friendly message.
    Log.e(
      '❌ [System Error] ${error.message}',
      error.originalError,
      error.stackTrace ?? st,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  } else {
    // Unknown error: Log it and show generic message.
    Log.e('❌ [Unknown Error] Unhandled exception', error, st);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.common_error_system),
        ),
      );
    }
  }
}
