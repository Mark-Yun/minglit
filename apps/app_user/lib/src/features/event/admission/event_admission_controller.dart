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
part 'event_admission_state.dart';

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
