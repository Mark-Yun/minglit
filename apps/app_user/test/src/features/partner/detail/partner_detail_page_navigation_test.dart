// Fix #2175: Regression guard for #2137 — PartnerDetailPage "더 보기" must route
// to /partners/:id/events. Verifies UI element → coordinator binding.
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockPartnerCoordinator extends Mock implements PartnerCoordinator {}

// Suppress Supabase.instance access in SocialInteractionController during tests
class _NoopSocialInteractionController extends SocialInteractionController {
  @override
  FutureOr<bool> build({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) => false;
}

void main() {
  late _MockPartnerCoordinator mockCoordinator;

  const testPartnerId = 'test-partner-id';
  const testPartner = Partner(
    id: testPartnerId,
    name: 'Test Partner',
    contactEmail: 'test@partner.com',
    bizName: 'Test Biz',
    representativeName: 'Test Rep',
    bizNumber: '123-45-67890',
  );

  setUp(() {
    mockCoordinator = _MockPartnerCoordinator();
    when(
      () => mockCoordinator.pushPartnerEvents(
        partnerId: any(named: 'partnerId'),
        partnerName: any(named: 'partnerName'),
      ),
    ).thenReturn(null);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        partnerCoordinatorProvider.overrideWithValue(mockCoordinator),
        partnerDetailProvider.overrideWith(
          (ref, id) async => testPartner,
        ),
        partnerEventsProvider.overrideWith(
          (ref, id) async => <Event>[],
        ),
        socialInteractionControllerProvider.overrideWith(
          _NoopSocialInteractionController.new,
        ),
      ],
      child: const MaterialApp(
        home: PartnerDetailPage(partnerId: testPartnerId),
      ),
    );
  }

  testWidgets(
    // Fix #2137: 더 보기 버튼이 /partners/:id/events가 아닌 Unknown Route로 이동하던 버그 회귀 가드
    '더 보기 탭 시 coordinator.pushPartnerEvents 호출 — #2137 회귀 가드',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('더 보기'));
      await tester.pumpAndSettle();

      verify(
        () => mockCoordinator.pushPartnerEvents(
          partnerId: testPartnerId,
          partnerName: testPartner.name,
        ),
      ).called(1);
    },
  );
}
