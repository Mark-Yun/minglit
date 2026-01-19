import 'dart:typed_data';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';

void main() {
  final adminClient = SupabaseClient(
    TestConfig.supabaseUrl,
    TestConfig.serviceRoleKey,
    headers: {
      'Authorization': 'Bearer ${TestConfig.serviceRoleKey}',
      'apikey': TestConfig.serviceRoleKey,
    },
  );

  SupabaseClient createUserClient(String userId) {
    final jwt = JWT({
      'sub': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'user_$userId@example.com',
    });
    final token = jwt.sign(SecretKey(TestConfig.jwtSecret));

    return SupabaseClient(
      TestConfig.supabaseUrl,
      TestConfig.serviceRoleKey,
      headers: {
        'Authorization': 'Bearer $token',
        'apikey': TestConfig.serviceRoleKey,
      },
    );
  }

  group('Storage Policy Tests', () {
    late String userId;

    setUpAll(() async {
      print('🚀 [Setup] Fetching test user...');
      final u = await adminClient
          .from('user_profiles')
          .select()
          .eq('username', 'user_25_m_ok')
          .single();
      userId = u['id'];
    });

    test('verification-proofs bucket should exist', () async {
      try {
        final bucket =
            await adminClient.storage.getBucket('verification-proofs');
        expect(bucket.id, equals('verification-proofs'));
      } on StorageException catch (e) {
        if (e.statusCode == '404' || e.message.contains('not found')) {
          fail(
              'Bucket "verification-proofs" not found. This is the detected bug.');
        }
        rethrow;
      }
    });

    test('authenticated user should be able to upload to own folder', () async {
      final userClient = createUserClient(userId);
      final fileData = Uint8List.fromList([1, 2, 3, 4]);
      final filePath = '$userId/test_file.txt';

      try {
        await userClient.storage.from('verification-proofs').uploadBinary(
              filePath,
              fileData,
              fileOptions: const FileOptions(upsert: true),
            );

        print('✅ Upload successful');
      } on StorageException catch (e) {
        fail('Upload failed: ${e.message} (Status: ${e.statusCode})');
      } finally {
        // Clean up
        try {
          await adminClient.storage
              .from('verification-proofs')
              .remove([filePath]);
        } catch (_) {}
      }
    });
    test('authenticated user should be able to upload PDF file', () async {
      final userClient = createUserClient(userId);
      final pdfData = Uint8List.fromList([37, 80, 68, 70, 45]); // %PDF- header
      final filePath = '$userId/test_doc.pdf';

      try {
        await userClient.storage.from('verification-proofs').uploadBinary(
              filePath,
              pdfData,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'application/pdf',
              ),
            );
        print('✅ PDF Upload successful');
      } on StorageException catch (e) {
        fail('PDF Upload failed: ${e.message} (Status: ${e.statusCode})');
      } finally {
        try {
          await adminClient.storage
              .from('verification-proofs')
              .remove([filePath]);
        } catch (_) {}
      }
    });
  });
}
