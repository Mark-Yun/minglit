// RecurrenceManagementScreenBuilder — recurrence_management_screen 전용 builder.
//
// RecurrenceManagementScreen 은 partyRecurrenceRuleProvider(partyId) 와
// recurrenceManagementControllerProvider 를 watch 한다.

import 'dart:async';

import 'package:app_partner/src/features/party/recurrence/recurrence_management_controller.dart';
import 'package:app_partner/src/features/party/recurrence/recurrence_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/data.dart';

const _mockPartyId = 'mock-party-1';

/// Fake controller that returns a fixed state without network calls.
class _FakeRecurrenceManagementController
    extends RecurrenceManagementController {
  _FakeRecurrenceManagementController({required this.loading});

  final bool loading;

  @override
  FutureOr<void> build() {
    if (loading) return Future<void>.delayed(const Duration(days: 1));
  }
}

class RecurrenceManagementScreenBuilder
    extends MdsScreenBuilder<RecurrenceManagementScreen> {
  RecurrenceManagementScreenBuilder()
    : super(
        page: const RecurrenceManagementScreen(partyId: _mockPartyId),
      );

  RecurrenceRule? _rule;
  bool _ruleLoadError = false;
  bool _loadingState = false;
  bool _actionLoading = false;
  Brightness _brightness = Brightness.light;

  /// 활성 규칙 (매주 월요일, 운영 중).
  RecurrenceManagementScreenBuilder withActiveRule() {
    _rule = mockRecurrenceRule();
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 일시 정지된 규칙.
  RecurrenceManagementScreenBuilder withPausedRule() {
    _rule = mockRecurrenceRule(status: RecurrenceStatus.paused);
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 취소된 규칙.
  RecurrenceManagementScreenBuilder withCancelledRule() {
    _rule = mockRecurrenceRule(status: RecurrenceStatus.cancelled);
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 규칙 없음 (null).
  RecurrenceManagementScreenBuilder withNoRule() {
    _rule = null;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 로드 에러.
  RecurrenceManagementScreenBuilder withLoadError() {
    _ruleLoadError = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 로딩 중 — provider AsyncLoading (fetch in progress).
  RecurrenceManagementScreenBuilder loading() {
    _loadingState = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 액션 진행 중 (버튼 disabled).
  RecurrenceManagementScreenBuilder withActionLoading() {
    _rule = mockRecurrenceRule();
    _actionLoading = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 다크 모드.
  RecurrenceManagementScreenBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final rule = _rule;
    final loadingState = _loadingState;
    final ruleLoadError = _ruleLoadError;
    final actionLoading = _actionLoading;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        partyRecurrenceRuleProvider(_mockPartyId).overrideWith((ref) async {
          if (ruleLoadError) throw Exception('규칙을 불러올 수 없습니다');
          if (loadingState) {
            await Future<void>.delayed(const Duration(days: 1));
          }
          return rule;
        }),
        recurrenceManagementControllerProvider.overrideWith(
          () => _FakeRecurrenceManagementController(loading: actionLoading),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const RecurrenceManagementScreen(partyId: _mockPartyId),
      ),
    );
  }
}
