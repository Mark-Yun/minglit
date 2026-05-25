import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockUser extends Mock implements User {}

class _MockIamportRepository extends Mock implements IamportRepository {}

class _IdentityConsentRepository extends ConsentRepository {
  _IdentityConsentRepository() : super(_MockSupabaseClient());

  @override
  Future<List<UserConsent>> getConsents(String userId) async {
    final now = DateTime(2026);
    return [
      UserConsent(
        id: 'consent-identity-verification',
        userId: userId,
        consentKey: ConsentType.identityVerification,
        consented: true,
        consentedAt: now,
        createdAt: now,
      ),
    ];
  }
}

User _makeUser() {
  final user = _MockUser();
  when(() => user.id).thenReturn('mock-user-1');
  return user;
}

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

base class _TestNavigatorObserver extends NavigatorObserver {
  bool popped = false;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped = true;
    super.didPop(route, previousRoute);
  }
}

void main() {
  group('IdentityVerificationScreen', () {
    // Fix #1271: consentControllerProvider (isAutoDispose=true)이 build()에서
    // watch되지 않으면 비동기 toggleConsent 호출 시 "Ref disposed" 에러 발생 (regression 방지).
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

    testWidgets(
      'renders retry state when certification returns null',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(_makeUser()),
              consentRepositoryProvider.overrideWithValue(
                _IdentityConsentRepository(),
              ),
            ],
            child: MaterialApp(
              home: IdentityVerificationScreen(
                certificationStarter:
                    ({
                      required context,
                      required userCode,
                      required merchantUid,
                      mRedirectUrl,
                    }) async => null,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('인증이 취소되었거나 창이 열리지 않았습니다.'), findsOne);
        expect(find.text('본인인증 다시 시도하기'), findsOne);
      },
    );

    testWidgets(
      'verifies certification and pops screen when certification succeeds',
      (tester) async {
        final iamportRepository = _MockIamportRepository();
        final observer = _TestNavigatorObserver();

        when(
          () => iamportRepository.verifyCertification(any()),
        ).thenAnswer((_) async => <String, dynamic>{'ok': true});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(_makeUser()),
              consentRepositoryProvider.overrideWithValue(
                _IdentityConsentRepository(),
              ),
              iamportRepositoryProvider.overrideWithValue(iamportRepository),
            ],
            child: MaterialApp(
              navigatorObservers: [observer],
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => IdentityVerificationScreen(
                                certificationStarter:
                                    ({
                                      required context,
                                      required userCode,
                                      required merchantUid,
                                      mRedirectUrl,
                                    }) async => 'imp_123',
                              ),
                            ),
                          );
                        },
                        child: const Text('open'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pumpAndSettle();

        verify(
          () => iamportRepository.verifyCertification('imp_123'),
        ).called(1);
        expect(observer.popped, isTrue);
      },
    );

    testWidgets(
      'renders generic error when certification starter throws',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(_makeUser()),
              consentRepositoryProvider.overrideWithValue(
                _IdentityConsentRepository(),
              ),
            ],
            child: MaterialApp(
              home: IdentityVerificationScreen(
                certificationStarter:
                    ({
                      required context,
                      required userCode,
                      required merchantUid,
                      mRedirectUrl,
                    }) async {
                      throw Exception('boom');
                    },
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('인증 중 오류가 발생했습니다.'), findsOne);
        expect(find.text('본인인증 다시 시도하기'), findsOne);
      },
    );
  });
}
