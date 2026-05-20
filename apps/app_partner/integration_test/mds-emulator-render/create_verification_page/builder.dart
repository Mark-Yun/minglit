// CreateVerificationPageBuilder — create_verification_page 전용 fluent API.
//
// CreateVerificationPage 는 createVerificationControllerProvider (순수 로컬 상태)
// 를 watch. 외부 async 의존성 없음 — controller fake 로 초기 state 주입.

import 'dart:async';

import 'package:app_partner/src/features/verification/create/create_verification_controller.dart';
import 'package:app_partner/src/features/verification/create/create_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

/// 고정 state 를 반환하는 fake controller.
class _FakeCreateVerificationController extends CreateVerificationController {
  _FakeCreateVerificationController({required this.initialState});

  final CreateVerificationState initialState;

  @override
  CreateVerificationState build() => initialState;
}

class CreateVerificationPageBuilder
    extends MdsScreenBuilder<CreateVerificationPage> {
  CreateVerificationPageBuilder() : super(page: const CreateVerificationPage());

  CreateVerificationState _state = const CreateVerificationState();
  Brightness _brightness = Brightness.light;

  /// 필드 없는 빈 폼 상태 (기본값).
  CreateVerificationPageBuilder empty() {
    _state = const CreateVerificationState();
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 텍스트 + 파일 필드가 추가된 상태.
  CreateVerificationPageBuilder withFields() {
    _state = const CreateVerificationState(
      displayName: '골프 핸디캡 인증',
      internalName: 'golf_handicap_2026',
      description: '핸디캡 증빙 서류를 제출해 주세요.',
      fields: [
        VerificationFormField(
          type: 'text',
          label: '핸디캡 수치',
          key: 'handicap_value',
        ),
        VerificationFormField(
          type: 'file',
          label: '증빙 파일',
          key: 'proof_file',
          required: false,
        ),
      ],
    );
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 다크 모드.
  CreateVerificationPageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final state = _state;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        createVerificationControllerProvider.overrideWith(
          () => _FakeCreateVerificationController(initialState: state),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const CreateVerificationPage(),
      ),
    );
  }
}
