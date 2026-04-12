import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// ProviderObserver that records the names of providers that have been
/// initialized in the container.
base class _ProviderInitObserver extends ProviderObserver {
  final List<String> initialized = [];

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    final name = context.provider.name ?? 'unnamed';
    initialized.add(name);
  }
}

void main() {
  group('IdentityVerificationScreen', () {
    // Fix #1271 regression: consentControllerProvider (isAutoDispose=true)이 build()에서
    // watch되지 않으면 비동기 toggleConsent 호출 시 "Ref disposed" 에러 발생.
    // build()에 ref.watch(consentControllerProvider)를 추가하여 화면 생명주기와 일치시킨다.
    testWidgets(
      'watches consentControllerProvider to prevent disposal during async flow',
      (tester) async {
        final observer = _ProviderInitObserver();

        // currentUserProvider = null → _ensureIdentityVerificationConsent이 즉시 false
        // 반환, getCertificationService() 호출을 방지한다.
        await tester.pumpWidget(
          ProviderScope(
            observers: [observer],
            overrides: [
              currentUserProvider.overrideWithValue(null),
            ],
            child: const MaterialApp(
              home: IdentityVerificationScreen(),
            ),
          ),
        );

        // postFrameCallback 및 async 상태 변경 처리
        await tester.pump();
        await tester.pump();

        // build()에서 ref.watch(consentControllerProvider)가 호출되면
        // 해당 provider가 container에 초기화(didAddProvider)된다.
        expect(
          observer.initialized,
          contains('consentControllerProvider'),
          reason:
              'consentControllerProvider는 build()에서 watch되어야 isAutoDispose로 인한 '
              'disposed 에러를 방지할 수 있다.',
        );
      },
    );

    testWidgets(
      'renders loading state initially',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(null),
            ],
            child: const MaterialApp(
              home: IdentityVerificationScreen(),
            ),
          ),
        );

        // 첫 프레임: loading state
        expect(find.byType(CircularProgressIndicator), findsAny);
      },
    );
  });
}
