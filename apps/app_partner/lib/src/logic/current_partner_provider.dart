import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_partner_provider.g.dart';

@riverpod
Future<Partner?> currentPartnerInfo(Ref ref) async {
  final authState = ref.watch(authStateChangesProvider).value;
  final user = authState?.session?.user;
  if (user == null) return null;

  final repo = ref.watch(partnerRepositoryProvider);
  // Fetch managed partners and return the first one as current context
  final partners = await repo.getMyManagedPartners();
  return partners.isNotEmpty ? partners.first : null;
}

/// Returns the current user's permission list for the active partner.
/// Empty list when partner or auth state is unavailable.
@riverpod
Future<List<String>> currentMemberPermissions(Ref ref) async {
  final partner = await ref.watch(currentPartnerInfoProvider.future);
  if (partner == null) return [];

  final repo = ref.watch(partnerRepositoryProvider);
  final memberRole = await repo.getMyMemberRole(partner.id);

  // Fix #1568: Fix #1533/#1217 전제와 일치 — partner_member_permissions 엔트리가
  // 없으면 승인된 신청서 폴백으로 접근한 owner이므로 전체 권한 부여.
  if (memberRole == null) return ['SETTLEMENT_VIEW', 'SETTLEMENT_EDIT'];

  return List<String>.from(
    memberRole['permissions'] as Iterable<dynamic>? ?? [],
  );
}

/// Fix #1533: 현재 사용자가 정산(SETTLEMENT_VIEW) 권한을 가지는지 확인.
///
/// - owner(폴백 포함) → true
/// - SETTLEMENT_VIEW 권한이 있는 manager/staff → true
/// - 그 외 → false (fail-closed)
///
/// 결제 웹뷰 복귀 후 역할 체크가 누락되던 문제의 근본 원인은
/// PartnerScaffold에 권한 기반 탭 가시성 제어가 없었기 때문.
final FutureProvider<bool> hasSettlementAccessProvider =
    FutureProvider.autoDispose<bool>((
      ref,
    ) async {
      final partner = await ref.watch(currentPartnerInfoProvider.future);
      if (partner == null) return false;

      final repo = ref.read(partnerRepositoryProvider);
      final memberRole = await repo.getMyMemberRole(partner.id);

      // Fix #1533: partner_member_permissions 엔트리가 없으면 승인된 신청서 폴백으로
      // 접근한 owner이므로 전체 권한 부여 (Fix #1217 참고).
      if (memberRole == null) return true;

      final permissions = memberRole['permissions'];
      if (permissions is List) {
        return permissions.contains('SETTLEMENT_VIEW');
      }
      return false;
    });
