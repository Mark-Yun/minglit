/// Base class for all Minglit exceptions.
abstract class MinglitException implements Exception {
  const MinglitException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// **User Exception**
///
/// An exception caused by user action or invalid input.
/// The [message] is safe to display to the user directly.
class MinglitUserException extends MinglitException {
  const MinglitUserException(super.message);
}

/// **System Exception**
///
/// An unexpected internal error (e.g., DB failure, Network error).
/// The [message] is for debugging, and [userMessage] is for the UI.
class MinglitSystemException extends MinglitException {
  const MinglitSystemException(
    super.message, {
    this.userMessage = '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
    this.originalError,
    this.stackTrace,
  });

  final String userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'MinglitSystemException: $message (Original: $originalError)';
}
