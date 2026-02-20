import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_admission_controller.g.dart';
part 'admission_action_handler.dart';
part 'ticket_recommendation_util.dart';

enum EventAdmissionStatus {
  guest, // 로그인 필요
  identityRequired, // 본인인증 필요 (기본 신뢰)
  qualificationRequired, // 자격 심사 필요 (직장, 학력 등)
  notEligible, // 나이/성별 조건 미달 (이 이벤트의 모든 티켓에 대해)
  eligible, // 조건 만족 (티켓 구매 가능)
  pendingPayment, // 결제 미완료 (이어하기)
  applied, // 이미 신청함/참여중 (결제 완료/심사 대기/승인)
  rejected, // 심사 거절됨 (재신청 가능하도록 유도)
}

/// **Admission State**
///
/// Holds the calculated status and detailed reasons.
class AdmissionState {
  AdmissionState({
    required this.status,
    this.user,
    this.ineligibleReason,
    this.rejectionReason,
    this.missingVerificationIds = const [],
  });

  final EventAdmissionStatus status;
  final User? user;
  final String? ineligibleReason;
  final String? rejectionReason;
  final List<String> missingVerificationIds;
}

enum AdmissionButtonStyle {
  normal,
  disabled,
  destructive,
}

class AdmissionButtonConfig {
  const AdmissionButtonConfig({
    required this.label,
    this.enabled = true,
    this.style = AdmissionButtonStyle.normal,
  });

  final String label;
  final bool enabled;
  final AdmissionButtonStyle style;
}

@riverpod
class EventAdmissionController extends _$EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
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

    var isAnyEligible = false;
    var isAnyQualificationNeeded = false;
    String? firstIneligibleReason;
    final allMissingIds = <String>{};

    for (final ticket in tickets) {
      final groups = entryGroups
          .where((g) => ticket.targetEntryGroupIds.contains(g.id))
          .toList();

      if (groups.isEmpty) {
        isAnyEligible = true;
        break;
      }

      for (final group in groups) {
        // A. Basic Condition Check (Age/Gender)
        final reason = _checkGroupCondition(group, userProfile);
        if (reason == null) {
          // B. Qualification Check
          final missingIds = group.requiredVerificationIds
              .where((id) => !userVerifIds.contains(id))
              .toList();

          if (missingIds.isEmpty) {
            isAnyEligible = true;
            break;
          } else {
            isAnyQualificationNeeded = true;
            allMissingIds.addAll(missingIds);
          }
        } else {
          firstIneligibleReason ??= reason;
        }
      }
      if (isAnyEligible) break;
    }

    if (isAnyEligible) {
      return AdmissionState(
        status: EventAdmissionStatus.eligible,
        user: currentUser,
      );
    }

    if (isAnyQualificationNeeded) {
      return AdmissionState(
        status: EventAdmissionStatus.qualificationRequired,
        user: currentUser,
        missingVerificationIds: allMissingIds.toList(),
      );
    }

    return AdmissionState(
      status: EventAdmissionStatus.notEligible,
      user: currentUser,
      ineligibleReason: firstIneligibleReason ?? '참여 조건이 맞지 않습니다.',
    );
  }

  /// Handles user action based on current admission state.
  Future<void> handleAction({
    required BuildContext context,
    required AdmissionState state,
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
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TicketSelectionSheet(event: event),
        );
        ref.invalidate(eventAdmissionControllerProvider(event));
        return;
      case EventAdmissionStatus.notEligible:
        return;
      case EventAdmissionStatus.eligible:
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TicketSelectionSheet(event: event),
          ),
        );
        return;
      case EventAdmissionStatus.pendingPayment:
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TicketSelectionSheet(event: event),
          ),
        );
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
            await ref
                .read(eventRepositoryProvider)
                .deleteApplication(
                  eventId: event.id,
                  userId: user.id,
                );
            ref.invalidate(eventAdmissionControllerProvider(event));
            if (context.mounted) {
              unawaited(
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => TicketSelectionSheet(event: event),
                ),
              );
            }
          } finally {
            loading.hide();
          }
        }
        return;
    }
  }

  /// Returns reason if NOT eligible, null if eligible.
  String? _checkGroupCondition(EntryGroup group, UserProfile user) {
    // 1. Gender Check
    if (group.gender != null) {
      // group.gender is 'male'/'female'. user.gender is 'male'/'female'.
      if (group.gender != user.gender) {
        return '성별 조건이 맞지 않습니다.';
      }
    }

    // 2. Age Check
    final birthDate = user.birthDate;
    if (birthDate == null) return '생년월일 정보가 없습니다.';

    final birthYear = birthDate.year;
    if (group.birthYearMin != null && birthYear < group.birthYearMin!) {
      return '${group.birthYearMin}년생 이상만 참여 가능합니다.';
    }
    if (group.birthYearMax != null && birthYear > group.birthYearMax!) {
      return '${group.birthYearMax}년생 이하만 참여 가능합니다.';
    }

    return null; // OK
  }
}
