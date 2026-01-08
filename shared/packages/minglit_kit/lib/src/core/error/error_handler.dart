import 'dart:async';
import 'dart:io';

import 'package:minglit_kit/src/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static Failure handle(dynamic error) {
    if (error is AuthException) {
      return Failure.auth(message: _mapAuthMessage(error));
    }

    if (error is PostgrestException) {
      return Failure.server(message: '데이터베이스 오류: ${error.message}');
    }

    if (error is SocketException || error is TimeoutException) {
      return const Failure.network();
    }

    if (error is StorageException) {
      return Failure.server(message: '파일 처리 오류: ${error.message}');
    }

    return Failure.unknown(message: error.toString());
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
