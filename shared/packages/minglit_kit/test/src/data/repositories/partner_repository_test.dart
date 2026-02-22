import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/partner_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late PartnerRepository repository;

  final now = DateTime.now();
  final mockUser = MockUser();

  final partnerJson = {
    'id': 'partner_1',
    'name': '밍글릿 클럽',
    'is_active': true,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    repository = PartnerRepository(supabase: mockClient);
  });

  group('PartnerRepository', () {
    group('getPartners', () {
      test('returns all active partners', () async {
        unawaited(mockTable(mockClient, 'partners', selectData: [partnerJson]));

        final result = await repository.getPartners();

        expect(result, hasLength(1));
        expect(result.first.id, 'partner_1');
        expect(result.first.name, '밍글릿 클럽');
      });

      test('returns empty list when no partners', () async {
        unawaited(mockTable(mockClient, 'partners', selectData: []));

        final result = await repository.getPartners();
        expect(result, isEmpty);
      });
    });

    group('getPartnerById', () {
      test('returns partner when found', () async {
        unawaited(mockTable(
          mockClient,
          'partners',
          maybeSingleData: partnerJson,
        ));

        final result = await repository.getPartnerById('partner_1');

        expect(result, isNotNull);
        expect(result!.id, 'partner_1');
        expect(result.name, '밍글릿 클럽');
      });

      test('returns null when not found', () async {
        unawaited(mockTable(
          mockClient,
          'partners',
        ));

        final result = await repository.getPartnerById('partner_unknown');
        expect(result, isNull);
      });
    });

    group('getMyManagedPartners', () {
      test('returns empty when user not logged in', () async {
        mockClient = createMockSupabase(); // no user
        repository = PartnerRepository(supabase: mockClient);

        final result = await repository.getMyManagedPartners();
        expect(result, isEmpty);
      });

      test('returns empty when no permissions', () async {
        unawaited(mockTable(
          mockClient,
          'partner_member_permissions',
          selectData: [],
        ));

        final result = await repository.getMyManagedPartners();
        expect(result, isEmpty);
      });

      test('returns managed partners when permissions exist', () async {
        unawaited(mockTable(
          mockClient,
          'partner_member_permissions',
          selectData: [
            {'partner_id': 'partner_1'},
          ],
        ));
        unawaited(mockTable(mockClient, 'partners', selectData: [partnerJson]));

        final result = await repository.getMyManagedPartners();

        expect(result, hasLength(1));
        expect(result.first.id, 'partner_1');
      });
    });

    group('getMyMemberRole', () {
      test('returns null when user not logged in', () async {
        mockClient = createMockSupabase(); // no user
        repository = PartnerRepository(supabase: mockClient);

        final result = await repository.getMyMemberRole('partner_1');
        expect(result, isNull);
      });

      test('returns role data when found', () async {
        unawaited(mockTable(
          mockClient,
          'partner_member_permissions',
          maybeSingleData: {
            'role': 'owner',
            'permissions': ['all'],
          },
        ));

        final result = await repository.getMyMemberRole('partner_1');

        expect(result, isNotNull);
        expect(result!['role'], 'owner');
      });
    });

    group('getPartnerRevenueStats', () {
      test('returns revenue stats', () async {
        final statsJson = {
          'partner_id': 'partner_1',
          'total_sales': 500000,
          'total_refunds': 30000,
          'net_amount': 470000,
        };

        unawaited(mockTable(
          mockClient,
          'partner_revenue_stats',
          maybeSingleData: statsJson,
        ));

        final result = await repository.getPartnerRevenueStats('partner_1');

        expect(result['total_sales'], 500000);
        expect(result['net_amount'], 470000);
      });

      test('returns default values when no data', () async {
        unawaited(mockTable(
          mockClient,
          'partner_revenue_stats',
        ));

        final result = await repository.getPartnerRevenueStats('partner_1');

        expect(result['total_sales'], 0);
        expect(result['net_amount'], 0);
      });
    });

    group('getPartnerMonthlyRevenue', () {
      test('returns monthly revenue list', () async {
        unawaited(mockTable(
          mockClient,
          'partner_monthly_revenue',
          selectData: [
            {'month': '2026-01', 'amount': 200000},
            {'month': '2026-02', 'amount': 300000},
          ],
        ));

        final result = await repository.getPartnerMonthlyRevenue('partner_1');

        expect(result, hasLength(2));
        expect(result.first['month'], '2026-01');
      });
    });

    group('getPartnerSettlements', () {
      test('returns settlement records', () async {
        unawaited(mockTable(
          mockClient,
          'settlements',
          selectData: [
            {
              'partner_id': 'partner_1',
              'event_date': '2026-02-15',
              'amount': 150000,
            },
          ],
        ));

        final result = await repository.getPartnerSettlements('partner_1');

        expect(result, hasLength(1));
        expect(result.first['amount'], 150000);
      });
    });
  });
}
