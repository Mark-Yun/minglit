import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/tag.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'tag_repository.g.dart';
part 'tag_repository_queries.dart';
part 'tag_repository_commands.dart';

/// Provider for TagRepository.
@Riverpod(keepAlive: true)
TagRepository tagRepository(Ref ref) {
  return TagRepository();
}

/// Repository for Tag-related data operations.
class TagRepository extends _SupabaseTagContextBase
    with _TagRepositoryQueries, _TagRepositoryCommands {
  /// Creates a [TagRepository] with a Supabase client.
  TagRepository({SupabaseClient? supabase})
    : super(supabase ?? Supabase.instance.client);
}

abstract class _SupabaseTagContext {
  SupabaseClient get supabaseClient;
}

abstract class _SupabaseTagContextBase implements _SupabaseTagContext {
  const _SupabaseTagContextBase(this.supabaseClient);

  @override
  final SupabaseClient supabaseClient;
}
