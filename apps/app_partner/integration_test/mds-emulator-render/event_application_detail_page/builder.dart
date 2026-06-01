import 'dart:async';

import 'package:app_partner/src/features/application/event_application_detail_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

const _mockApplicationId = 'render-event-application-id';

enum _EventApplicationDetailScenario {
  pendingReview,
  approved,
  rejected,
  paid,
  rejectDialog,
  loading,
}

class _AutoShowRejectDialog extends StatefulWidget {
  const _AutoShowRejectDialog({required this.child});

  final Widget child;

  @override
  State<_AutoShowRejectDialog> createState() => _AutoShowRejectDialogState();
}

class _AutoShowRejectDialogState extends State<_AutoShowRejectDialog> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('거절 사유'),
            content: const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '거절 사유를 입력해주세요 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(onPressed: () {}, child: const Text('취소')),
              TextButton(onPressed: () {}, child: const Text('거절')),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class EventApplicationDetailPageBuilder
    extends MdsScreenBuilder<EventApplicationDetailPage> {
  EventApplicationDetailPageBuilder()
    : super(
        page: const EventApplicationDetailPage(
          applicationId: _mockApplicationId,
        ),
      );

  _EventApplicationDetailScenario _scenario =
      _EventApplicationDetailScenario.pendingReview;

  EventApplicationDetailPageBuilder pendingReview() {
    _scenario = _EventApplicationDetailScenario.pendingReview;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationDetailPageBuilder approved() {
    _scenario = _EventApplicationDetailScenario.approved;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationDetailPageBuilder rejected() {
    _scenario = _EventApplicationDetailScenario.rejected;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationDetailPageBuilder paid() {
    _scenario = _EventApplicationDetailScenario.paid;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationDetailPageBuilder rejectDialog() {
    _scenario = _EventApplicationDetailScenario.rejectDialog;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationDetailPageBuilder loading() {
    _scenario = _EventApplicationDetailScenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenario = _scenario;
    final Widget home = scenario == _EventApplicationDetailScenario.rejectDialog
        ? const _AutoShowRejectDialog(
            child: EventApplicationDetailPage(
              applicationId: _mockApplicationId,
            ),
          )
        : const EventApplicationDetailPage(applicationId: _mockApplicationId);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        eventApplicationDetailProvider(
          _mockApplicationId,
        ).overrideWith((ref) async {
          switch (scenario) {
            case _EventApplicationDetailScenario.pendingReview:
            case _EventApplicationDetailScenario.rejectDialog:
              return _buildApplication(status: 'pending_review');
            case _EventApplicationDetailScenario.approved:
              return _buildApplication(
                status: 'approved',
                paymentAmount: 39000,
              );
            case _EventApplicationDetailScenario.rejected:
              return _buildApplication(
                status: 'rejected',
                rejectionReason: '모집 대상 조건과 맞지 않습니다.',
              );
            case _EventApplicationDetailScenario.paid:
              return _buildApplication(
                status: 'paid',
                paymentAmount: 39000,
                paidAt: DateTime(2026, 5, 29, 11, 20),
              );
            case _EventApplicationDetailScenario.loading:
              return Completer<EventApplication?>().future;
          }
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: MinglitTheme.materialTheme,
        home: home,
      ),
    );
  }

  EventApplication _buildApplication({
    required String status,
    int? paymentAmount,
    String? rejectionReason,
    DateTime? paidAt,
  }) {
    final createdAt = DateTime(2026, 5, 29, 9, 30);
    return EventApplication(
      id: _mockApplicationId,
      eventId: 'render-event-id',
      ticketId: 'render-ticket-id',
      userId: 'render-user-id',
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
      paymentAmount: paymentAmount,
      rejectionReason: rejectionReason,
      paidAt: paidAt,
      user: UserProfile(
        id: 'render-user-id',
        name: '김민수',
        username: 'mingsu',
        gender: 'male',
        birthYear: 1998,
        birthDate: DateTime(1998, 4, 7),
      ),
    );
  }
}
