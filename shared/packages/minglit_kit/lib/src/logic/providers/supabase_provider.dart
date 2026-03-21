import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

@Riverpod(keepAlive: true)

/// Provides the shared [SupabaseClient] instance.
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}
