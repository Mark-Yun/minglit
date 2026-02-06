BEGIN;
SELECT plan(63);

-- user_profiles
SELECT has_table('user_profiles');
SELECT has_column('user_profiles', 'id');
SELECT has_column('user_profiles', 'username');
SELECT has_column('user_profiles', 'name');
SELECT has_column('user_profiles', 'phone_number');
SELECT has_column('user_profiles', 'birth_date');
SELECT has_column('user_profiles', 'gender');
SELECT has_column('user_profiles', 'is_verified');
SELECT has_column('user_profiles', 'ci');
SELECT has_column('user_profiles', 'di');
SELECT has_column('user_profiles', 'created_at');
SELECT has_column('user_profiles', 'updated_at');
SELECT col_type_is('user_profiles', 'id', 'uuid');
SELECT col_is_pk('user_profiles', 'id');
SELECT col_is_fk('user_profiles', 'id');
SELECT col_not_null('user_profiles', 'id');
SELECT col_type_is('user_profiles', 'gender', 'gender');
SELECT col_type_is('user_profiles', 'created_at', 'timestamp with time zone');
SELECT col_has_default('user_profiles', 'created_at');
SELECT col_type_is('user_profiles', 'updated_at', 'timestamp with time zone');
SELECT col_has_default('user_profiles', 'updated_at');
SELECT col_has_default('user_profiles', 'is_verified');

-- user_embeddings
SELECT has_table('user_embeddings');
SELECT has_column('user_embeddings', 'user_id');
SELECT has_column('user_embeddings', 'embedding');
SELECT has_column('user_embeddings', 'updated_at');
SELECT col_type_is('user_embeddings', 'user_id', 'uuid');
SELECT col_is_pk('user_embeddings', 'user_id');
SELECT col_is_fk('user_embeddings', 'user_id');
SELECT col_not_null('user_embeddings', 'user_id');
SELECT col_type_is('user_embeddings', 'updated_at', 'timestamp with time zone');
SELECT col_has_default('user_embeddings', 'updated_at');
SELECT has_index('user_embeddings', 'user_embeddings_embedding_idx');

-- app_roles
SELECT has_table('app_roles');
SELECT has_column('app_roles', 'user_id');
SELECT has_column('app_roles', 'role');
SELECT has_column('app_roles', 'created_at');
SELECT col_type_is('app_roles', 'user_id', 'uuid');
SELECT col_is_pk('app_roles', 'user_id');
SELECT col_is_fk('app_roles', 'user_id');
SELECT col_not_null('app_roles', 'user_id');
SELECT col_not_null('app_roles', 'role');
SELECT col_type_is('app_roles', 'created_at', 'timestamp with time zone');
SELECT col_has_default('app_roles', 'created_at');

-- user_actions
SELECT has_table('user_actions');
SELECT has_column('user_actions', 'id');
SELECT has_column('user_actions', 'user_id');
SELECT has_column('user_actions', 'party_id');
SELECT has_column('user_actions', 'action_type');
SELECT has_column('user_actions', 'created_at');
SELECT col_type_is('user_actions', 'id', 'uuid');
SELECT col_is_pk('user_actions', 'id');
SELECT col_has_default('user_actions', 'id');
SELECT col_type_is('user_actions', 'user_id', 'uuid');
SELECT col_is_fk('user_actions', 'user_id');
SELECT col_not_null('user_actions', 'user_id');
SELECT col_type_is('user_actions', 'party_id', 'uuid');
SELECT col_not_null('user_actions', 'party_id');
SELECT col_type_is('user_actions', 'action_type', 'user_action_type');
SELECT col_not_null('user_actions', 'action_type');
SELECT col_type_is('user_actions', 'created_at', 'timestamp with time zone');
SELECT col_has_default('user_actions', 'created_at');
SELECT has_index('user_actions', 'user_actions_user_id_idx');

SELECT * FROM finish();
ROLLBACK;
