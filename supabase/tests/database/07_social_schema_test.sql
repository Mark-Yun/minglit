BEGIN;
SELECT plan(20);

-- social_interactions
SELECT has_table('social_interactions');
SELECT has_column('social_interactions', 'user_id');
SELECT has_column('social_interactions', 'target_id');
SELECT has_column('social_interactions', 'target_type');
SELECT has_column('social_interactions', 'interaction_type');
SELECT has_column('social_interactions', 'created_at');
SELECT col_type_is('social_interactions', 'user_id', 'uuid');
SELECT col_is_fk('social_interactions', 'user_id');
SELECT col_not_null('social_interactions', 'user_id');
SELECT col_type_is('social_interactions', 'target_id', 'uuid');
SELECT col_not_null('social_interactions', 'target_id');
SELECT col_type_is('social_interactions', 'target_type', 'social_target_type');
SELECT col_not_null('social_interactions', 'target_type');
SELECT col_type_is('social_interactions', 'interaction_type', 'social_interaction_type');
SELECT col_not_null('social_interactions', 'interaction_type');
SELECT col_type_is('social_interactions', 'created_at', 'timestamp with time zone');
SELECT col_has_default('social_interactions', 'created_at');
SELECT has_pk('social_interactions');
SELECT has_index('social_interactions', 'idx_social_interactions_target');
SELECT has_index('social_interactions', 'idx_social_interactions_user');

SELECT * FROM finish();
ROLLBACK;
