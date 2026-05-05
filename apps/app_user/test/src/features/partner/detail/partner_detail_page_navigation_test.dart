// Fix #2175: Regression guard for #2137 — PartnerDetailPage "더 보기" must push
// /partners/:id/events to GoRouter. Verifies UI element → route destination binding
// by injecting a real PartnerCoordinator with a MockGoRouter and asserting the
// exact push path — coordinator method regressions are caught at the route level.
import 'dart:async';

import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/features/social/logic/social_interaction_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoRouter extends Mock implements GoRouter {}

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
  late _MockGoRouter mockRouter;

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
    mockRouter = _MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        // Use real coordinator with mock router — verifies the push path, not just the call
        partnerCoordinatorProvider.overrideWithValue(
          PartnerCoordinator(mockRouter),
        ),
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
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const PartnerDetailPage(partnerId: testPartnerId),
      ),
    );
  }

  testWidgets(
    // Fix #2137: 더 보기 버튼이 Unknown Route로 이동하던 버그 회귀 가드
    // — 라우터에 /partners/:id/events가 실제로 push되는지 검증
    '더 보기 탭 시 /partners/:id/events push — #2137 회귀 가드',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('더 보기'));
      await tester.pumpAndSettle();

      verify(
        () => mockRouter.push(
          const PartnerEventsRoute(partnerId: testPartnerId).location,
        ),
      ).called(1);
    },
  );
}
