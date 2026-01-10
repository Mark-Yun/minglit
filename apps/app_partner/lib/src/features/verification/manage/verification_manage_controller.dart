import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verification_manage_controller.g.dart';

/// State class for managing verification lists
class VerificationManageState {
  const VerificationManageState({
    this.active = const [],
    this.archived = const [],
  });

  final List<Verification> active;
  final List<Verification> archived;

  VerificationManageState copyWith({
    List<Verification>? active,
    List<Verification>? archived,
  }) {
    return VerificationManageState(
      active: active ?? this.active,
      archived: archived ?? this.archived,
    );
  }
}

@riverpod
class VerificationManageController extends _$VerificationManageController {
  @override
  FutureOr<VerificationManageState> build() async {
    final partner = await ref.watch(currentPartnerInfoProvider.future);
    if (partner == null) return const VerificationManageState();

    final repo = ref.watch(verificationRepositoryProvider);

    // Fetch both Active and Archived in parallel
    final results = await Future.wait([
      repo.getPartnerVerifications(partner.id),
      repo.getPartnerVerifications(partner.id, isActive: false),
    ]);

    return VerificationManageState(
      active: results[0],
      archived: results[1],
    );
  }

  /// Archives (soft-deletes) the verification.
  Future<void> archiveVerification(String verificationId) async {
    final repo = ref.read(verificationRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.deleteVerification(verificationId);
      // Re-fetch to update lists
      return _fetchLists();
    });
  }

  /// Restores the verification.
  Future<void> restoreVerification(String verificationId) async {
    final repo = ref.read(verificationRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.restoreVerification(verificationId);
      // Re-fetch to update lists
      return _fetchLists();
    });
  }

  Future<VerificationManageState> _fetchLists() async {
    final partner = await ref.read(currentPartnerInfoProvider.future);
    if (partner == null) return const VerificationManageState();

    final repo = ref.read(verificationRepositoryProvider);
    final results = await Future.wait([
      repo.getPartnerVerifications(partner.id),
      repo.getPartnerVerifications(partner.id, isActive: false),
    ]);

    return VerificationManageState(
      active: results[0],
      archived: results[1],
    );
  }
}
