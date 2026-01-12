import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for all Minglit exceptions.
abstract class MinglitException implements Exception {
  const MinglitException(this.message);
  final String message;

  @override
  String toString() => message;

  /// Automatically converts any object into a [MinglitException].
  static MinglitException from(Object error, [StackTrace? stackTrace]) {
    if (error is MinglitException) return error;

    if (error is AuthException) {
      return MinglitAuthException(
        _mapAuthMessage(error),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException) {
      return MinglitSystemException(
        'Database error: ${error.message}',
        userMessage: '데이터베이스 통신 중 오류가 발생했습니다.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is SocketException || error is TimeoutException) {
      return MinglitSystemException(
        'Network error',
        userMessage: '네트워크 연결이 불안정합니다. 연결 상태를 확인해주세요.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic fallback
    return MinglitSystemException(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static String _mapAuthMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (message.contains('email not confirmed')) {
      return '이메일 인증이 필요합니다.';
    }
    if (message.contains('user already exists')) {
      return '이미 가입된 이메일입니다.';
    }
    return error.message;
  }
}

/// **User Exception**
///
/// An exception caused by user action or invalid input.
/// The [message] is safe to display to the user directly.
class MinglitUserException extends MinglitException {
  const MinglitUserException(super.message);
}

/// **Auth Exception**
///
/// Authentication specific errors (Login, Token expire, etc).
class MinglitAuthException extends MinglitException {
  const MinglitAuthException(
    super.message, {
    this.originalError,
    this.stackTrace,
  });
  final dynamic originalError;
  final StackTrace? stackTrace;
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
