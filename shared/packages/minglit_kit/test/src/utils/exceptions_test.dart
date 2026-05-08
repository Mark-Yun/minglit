import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('MinglitException.from', () {
    test('returns same instance if already MinglitException', () {
      const original = MinglitUserException('test error');
      final result = MinglitException.from(original);
      expect(identical(result, original), isTrue);
    });

    test('wraps AuthException into MinglitAuthException', () {
      const authError = AuthException('some auth error');
      final result = MinglitException.from(authError);

      expect(result, isA<MinglitAuthException>());
      expect((result as MinglitAuthException).originalError, authError);
    });

    test('maps invalid login credentials message', () {
      const authError = AuthException('Invalid login credentials');
      final result = MinglitException.from(authError);

      expect(result.message, '이메일 또는 비밀번호가 올바르지 않습니다.');
    });

    test('maps email not confirmed message', () {
      const authError = AuthException('Email not confirmed');
      final result = MinglitException.from(authError);

      expect(result.message, '이메일 인증이 필요합니다.');
    });

    test('maps user already exists message', () {
      const authError = AuthException('User already exists');
      final result = MinglitException.from(authError);

      expect(result.message, '이미 가입된 이메일입니다.');
    });

    test('wraps PostgrestException into MinglitSystemException', () {
      const pgError = PostgrestException(message: 'relation not found');
      final result = MinglitException.from(pgError);

      expect(result, isA<MinglitSystemException>());
      expect(result.message, contains('Database error'));
      expect(
        (result as MinglitSystemException).userMessage,
        '데이터베이스 통신 중 오류가 발생했습니다.',
      );
    });

    test('wraps SocketException into network error', () {
      const socketError = SocketException('Connection refused');
      final result = MinglitException.from(socketError);

      expect(result, isA<MinglitSystemException>());
      expect(
        (result as MinglitSystemException).userMessage,
        contains('네트워크'),
      );
    });

    test('wraps TimeoutException into network error', () {
      final timeoutError = TimeoutException('Request timed out');
      final result = MinglitException.from(timeoutError);

      expect(result, isA<MinglitSystemException>());
      expect(
        (result as MinglitSystemException).userMessage,
        contains('네트워크'),
      );
    });

    // Fix #2318: FunctionException with validation_failed must surface the
    // field-level error, not fall through to the generic system error.
    test(
        'maps FunctionException validation_failed to MinglitUserException with field message',
        () {
      final funcError = FunctionException(
        status: 400,
        details: {
          'error': 'validation_failed',
          'details': [
            {'field': 'biz_number', 'message': '올바른 사업자번호 형식이 아닙니다'},
          ],
        },
      );
      final result = MinglitException.from(funcError);

      expect(result, isA<MinglitUserException>());
      expect(result.message, '올바른 사업자번호 형식이 아닙니다');
      expect((result as MinglitUserException).details, hasLength(1));
    });

    test(
        'maps FunctionException validation_failed without field message to generic prompt',
        () {
      final funcError = FunctionException(
        status: 400,
        details: {'error': 'validation_failed', 'details': <dynamic>[]},
      );
      final result = MinglitException.from(funcError);

      expect(result, isA<MinglitUserException>());
      expect(result.message, '입력 정보를 확인해주세요');
    });

    test('maps non-validation FunctionException to MinglitSystemException', () {
      final funcError = FunctionException(
        status: 500,
        details: {'error': 'internal_error'},
        reasonPhrase: 'Internal Server Error',
      );
      final result = MinglitException.from(funcError);

      expect(result, isA<MinglitSystemException>());
    });

    test('wraps generic error into MinglitSystemException', () {
      final result = MinglitException.from(Exception('unknown'));

      expect(result, isA<MinglitSystemException>());
      expect(result.message, contains('unknown'));
    });

    test('preserves stack trace', () {
      final stackTrace = StackTrace.current;
      final result = MinglitException.from(
        Exception('with trace'),
        stackTrace,
      );

      expect(result, isA<MinglitSystemException>());
      expect((result as MinglitSystemException).stackTrace, stackTrace);
    });
  });

  group('MinglitUserException', () {
    test('toString returns message', () {
      const error = MinglitUserException('user error');
      expect(error.toString(), 'user error');
    });
  });

  group('MinglitSystemException', () {
    test('has default user message', () {
      const error = MinglitSystemException('internal');
      expect(error.userMessage, contains('일시적인 오류'));
    });

    test('toString includes original error', () {
      const error = MinglitSystemException(
        'internal',
        originalError: 'root cause',
      );
      expect(error.toString(), contains('root cause'));
    });
  });
}
