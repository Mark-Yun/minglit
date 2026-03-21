import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/data/models/verification_submission.dart';

void main() {
  final now = DateTime(2026, 1, 15, 12);

  group('VerificationSubmission', () {
    Map<String, dynamic> submissionJson() => {
          'id': 'sub_1',
          'partner_id': 'partner_1',
          'user_id': 'user_1',
          'verification_id': 'verif_1',
          'status': 'pending',
          'snapshot_data': {
            'company': 'Minglit Inc',
            'position': 'Developer',
          },
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'application_id': 'app_1',
          'admin_comment': 'Please resubmit',
          'reviewed_at': now.toIso8601String(),
          'reviewed_by': 'admin_1',
        };

    test('creates from JSON with all fields', () {
      final sub = VerificationSubmission.fromJson(submissionJson());

      expect(sub.id, 'sub_1');
      expect(sub.partnerId, 'partner_1');
      expect(sub.userId, 'user_1');
      expect(sub.verificationId, 'verif_1');
      expect(sub.status, VerificationStatus.pending);
      expect(sub.snapshotData['company'], 'Minglit Inc');
      expect(sub.applicationId, 'app_1');
      expect(sub.adminComment, 'Please resubmit');
      expect(sub.reviewedBy, 'admin_1');
    });

    test('creates with required fields only', () {
      final sub = VerificationSubmission.fromJson({
        'id': 'sub_2',
        'partner_id': 'p1',
        'user_id': 'u1',
        'verification_id': 'v1',
        'status': 'approved',
        'snapshot_data': <String, dynamic>{},
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      expect(sub.status, VerificationStatus.approved);
      expect(sub.applicationId, isNull);
      expect(sub.adminComment, isNull);
      expect(sub.reviewedAt, isNull);
      expect(sub.reviewedBy, isNull);
    });

    test('parses all status values', () {
      for (final status in [
        'pending',
        'approved',
        'rejected',
        'needs_correction',
        'cancelled',
      ]) {
        final sub = VerificationSubmission.fromJson({
          'id': 'sub_1',
          'partner_id': 'p1',
          'user_id': 'u1',
          'verification_id': 'v1',
          'status': status,
          'snapshot_data': <String, dynamic>{},
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        expect(sub.status, isNotNull);
      }
    });

    test('serializes to JSON and back', () {
      final original = VerificationSubmission.fromJson(submissionJson());
      final json = original.toJson();
      final restored = VerificationSubmission.fromJson(json);

      expect(restored, equals(original));
    });

    test('equality works', () {
      final s1 = VerificationSubmission.fromJson(submissionJson());
      final s2 = VerificationSubmission.fromJson(submissionJson());
      expect(s1, equals(s2));
    });

    test('copyWith creates modified copy', () {
      final sub = VerificationSubmission.fromJson(submissionJson());
      final approved = sub.copyWith(
        status: VerificationStatus.approved,
        adminComment: 'Approved!',
      );

      expect(approved.status, VerificationStatus.approved);
      expect(approved.adminComment, 'Approved!');
      expect(approved.id, 'sub_1');
    });
  });
}
