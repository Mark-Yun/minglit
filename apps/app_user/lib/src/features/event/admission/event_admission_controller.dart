import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/widgets/event_now_phases/results_content.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_admission_controller.g.dart';
part 'admission_action_handler.dart';
part 'event_admission_state.dart';

@riverpod
class EventAdmissionController extends _$EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
    // Fix #1208: Check event status before any user-state logic.
    // Completed/cancelled events show ended-state CTAs regardless of login/eligibility.
    final isEnded = event.status == 'completed' || event.status == 'cancelled';
    if (isEnded) {
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser == null) {
        return AdmissionState(status: EventAdmissionStatus.eventEnded);
      }

      final existingApp = await ref
          .watch(eventRepositoryProvider)
          .getApplication(
            eventId: event.id,
            userId: currentUser.id,
          );

      // rejected: user did not participate — treat same as cancelled for ended events
      final hasActiveApplication =
          existingApp != null &&
          existingApp.status != 'cancelled' &&
          existingApp.status != 'rejected';

      if (!hasActiveApplication) {
        return AdmissionState(
          status: EventAdmissionStatus.eventEnded,
          user: currentUser,
        );
      }

      // Check for match results
      final matchingRepo = ref.watch(matchingRepositoryProvider);
      final matches = await matchingRepo.getMyMatches(event.id);

      if (matches.isNotEmpty) {
        return AdmissionState(
          status: EventAdmissionStatus.eventEndedWithResults,
          user: currentUser,
        );
      }

      return AdmissionState(
        status: EventAdmissionStatus.eventEndedParticipated,
        user: currentUser,
      );
    }

    final currentUser = ref.watch(currentUserProvider);
    final repository = ref.watch(eventRepositoryProvider);
    final userRepository = ref.watch(userRepositoryProvider);

    // 1. Check Login
    if (currentUser == null) {
      return AdmissionState(status: EventAdmissionStatus.guest);
    }

    // 2. Check Existing Application (DB Check)
    final existingApp = await repository.getApplication(
      eventId: event.id,
      userId: currentUser.id,
    );

    if (existingApp != null) {
      if (existingApp.status == 'pending') {
        return AdmissionState(
          status: EventAdmissionStatus.pendingPayment,
          user: currentUser,
        );
      }
      if (existingApp.status == 'rejected') {
        return AdmissionState(
          status: EventAdmissionStatus.rejected,
          user: currentUser,
          rejectionReason: existingApp.rejectionReason,
        );
      }
      if (existingApp.status != 'cancelled') {
        return AdmissionState(
          status: EventAdmissionStatus.applied,
          user: currentUser,
        );
      }
    }

    // 3. Fetch User Profile (Identity Check)
    final userProfile = await userRepository.getUserProfile(currentUser.id);

    if (userProfile == null || !userProfile.isVerified) {
      return AdmissionState(
        status: EventAdmissionStatus.identityRequired,
        user: currentUser,
      );
    }

    // 4. Fetch User's Approved Verifications
    final userVerifIds = await userRepository.getApprovedVerificationIds(
      currentUser.id,
    );

    // 5. Check Eligibility & Qualifications
    final tickets = event.tickets ?? [];
    final entryGroups = event.entryGroups ?? [];

    if (tickets.isEmpty) {
      return AdmissionState(
        status: EventAdmissionStatus.eligible,
        user: currentUser,
      );
    }

    return _checkEligibility(
      tickets: tickets,
      entryGroups: entryGroups,
      userProfile: userProfile,
      userVerifIds: userVerifIds,
      currentUser: currentUser,
    );
  }

  // Fix #453: showTicketSelection 콜백으로 ticket feature 직접 참조 제거 — 순환 참조 해소
  /// Handles user action based on current admission state.
  Future<void> handleAction({
    required BuildContext context,
    required AdmissionState state,
    required VoidCallback showTicketSelection,
  }) async {
    switch (state.status) {
      case EventAdmissionStatus.guest:
        final currentPath = GoRouterState.of(context).uri.toString();
        ref.read(authCoordinatorProvider).goToLogin(from: currentPath);
        return;
      case EventAdmissionStatus.identityRequired:
        final success = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const IdentityVerificationScreen(),
            fullscreenDialog: true,
          ),
        );
        if (success ?? false) {
          ref.invalidate(eventAdmissionControllerProvider(event));
        }
        return;
      case EventAdmissionStatus.qualificationRequired:
        showTicketSelection();
        ref.invalidate(eventAdmissionControllerProvider(event));
        return;
      case EventAdmissionStatus.notEligible:
        return;
      case EventAdmissionStatus.eligible:
        showTicketSelection();
        return;
      case EventAdmissionStatus.pendingPayment:
        showTicketSelection();
        return;
      case EventAdmissionStatus.applied:
        handleMinglitError(
          context,
          const MinglitUserException(
            '이미 신청이 완료된 이벤트입니다.\n마이페이지에서 티켓을 확인해주세요.',
          ),
        );
        return;
      case EventAdmissionStatus.rejected:
        final confirmed = await context.showMinglitConfirm(
          title: '심사 결과 안내',
          message:
              '반려 사유: ${state.rejectionReason ?? "정보 부족"}\n\n'
              '기존 신청을 취소하고 다시 신청하시겠습니까?',
          confirmLabel: '다시 신청하기',
          cancelLabel: '닫기',
        );

        if (confirmed && context.mounted) {
          final user = state.user;
          if (user == null) return;
          final loading = ref.read(globalLoadingControllerProvider.notifier)
            ..show();
          try {
            // Fix #299: deleteApplication → cancelOrder EF 전환
            await ref
                .read(eventRepositoryProvider)
                .cancelOrder(eventId: event.id);
            ref.invalidate(eventAdmissionControllerProvider(event));
            if (context.mounted) {
              showTicketSelection();
            }
          } finally {
            loading.hide();
          }
        }
        return;
      // Fix #1208: Ended event CTA actions
      case EventAdmissionStatus.eventEnded:
      case EventAdmissionStatus.eventEndedParticipated:
        return;
      case EventAdmissionStatus.eventEndedWithResults:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MinglitRadius.card),
            ),
          ),
          builder: (sheetContext) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewPadding.bottom,
              ),
              // ResultsContent only reads activeEvent.event (title)
              // and myMatchesProvider(event.id) — participantStatus is unused.
              child: ResultsContent(
                activeEvent: TodayActiveEvent(
                  event: event,
                  participantStatus: 'checked_in',
                ),
              ),
            ),
          ),
        );
        return;
    }
  }
}
