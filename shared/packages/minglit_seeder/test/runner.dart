import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_seeder/database_seeder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Run Database Seeder', () async {
    // Enable real HTTP requests
    HttpOverrides.global = null;

    // 1. Get Environment Variables
    final url = Platform.environment['SUPABASE_URL'];
    final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

    if (url == null || key == null) {
      print('⚠️ [Seeder] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.');
      print(
        '   Skipping seed execution. (This is expected during build/test unless env vars are set)',
      );
      return;
    }

    print('🚀 [Seeder] Initializing Supabase Client...');
    print('   URL: $url');
    
    // Debug: Check JWT Role
    try {
      final parts = key.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> json = jsonDecode(decoded);
        print('   🔑 Key Role: ${json['role']}'); // Should be 'service_role'
        
        // 🔍 Debug: Try Raw HTTP Request to verify permissions bypassing SDK
        print('   🔍 Testing Raw HTTP Access to verifications...');
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse('$url/rest/v1/verifications?select=count'));
        request.headers.set('apikey', key);
        request.headers.set('Authorization', 'Bearer $key');
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();
        print('   🔍 Raw Response Code: ${response.statusCode}');
        if (response.statusCode != 200) {
           print('   🔥 Raw Request Failed: $responseBody');
        } else {
           print('   ✅ Raw Request Success! SDK might be the issue.');
        }
      }
    } catch (e) {
      print('   ⚠️ Debugging failed: $e');
    }

    // Initialize Client with specific options to avoid session interference
    final client = SupabaseClient(
      url,
      key,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final seeder = DatabaseSeeder(client);

    await seeder.seed();
  });
}
