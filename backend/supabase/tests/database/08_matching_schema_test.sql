BEGIN;
SELECT plan(64);

-- match_rules
SELECT has_table('match_rules');
SELECT has_column('match_rules', 'id');
SELECT has_column('match_rules', 'event_id');
SELECT has_column('match_rules', 'source_group_id');
SELECT has_column('match_rules', 'target_group_id');
SELECT has_column('match_rules', 'created_at');
SELECT col_type_is('match_rules', 'id', 'uuid');
SELECT col_is_pk('match_rules', 'id');
SELECT col_has_default('match_rules', 'id');
SELECT col_not_null('match_rules', 'id');
SELECT col_type_is('match_rules', 'event_id', 'uuid');
SELECT col_is_fk('match_rules', 'event_id');
SELECT col_not_null('match_rules', 'event_id');
SELECT col_type_is('match_rules', 'source_group_id', 'uuid');
SELECT col_is_fk('match_rules', 'source_group_id');
SELECT col_not_null('match_rules', 'source_group_id');
SELECT col_type_is('match_rules', 'target_group_id', 'uuid');
SELECT col_is_fk('match_rules', 'target_group_id');
SELECT col_not_null('match_rules', 'target_group_id');
SELECT col_type_is('match_rules', 'created_at', 'timestamp with time zone');
SELECT col_has_default('match_rules', 'created_at');
SELECT has_index('match_rules', 'idx_match_rules_event');

-- match_votes
SELECT has_table('match_votes');
SELECT has_column('match_votes', 'event_id');
SELECT has_column('match_votes', 'voter_id');
SELECT has_column('match_votes', 'candidate_id');
SELECT has_column('match_votes', 'created_at');
SELECT col_type_is('match_votes', 'event_id', 'uuid');
SELECT col_is_fk('match_votes', 'event_id');
SELECT col_not_null('match_votes', 'event_id');
SELECT col_type_is('match_votes', 'voter_id', 'uuid');
SELECT col_is_fk('match_votes', 'voter_id');
SELECT col_not_null('match_votes', 'voter_id');
SELECT col_type_is('match_votes', 'candidate_id', 'uuid');
SELECT col_is_fk('match_votes', 'candidate_id');
SELECT col_not_null('match_votes', 'candidate_id');
SELECT col_type_is('match_votes', 'created_at', 'timestamp with time zone');
SELECT col_has_default('match_votes', 'created_at');
SELECT has_pk('match_votes');
SELECT has_index('match_votes', 'idx_match_votes_event');
SELECT has_index('match_votes', 'idx_match_votes_voter');

-- match_pairs
SELECT has_table('match_pairs');
SELECT has_column('match_pairs', 'id');
SELECT has_column('match_pairs', 'event_id');
SELECT has_column('match_pairs', 'user_lower_id');
SELECT has_column('match_pairs', 'user_higher_id');
SELECT has_column('match_pairs', 'matched_at');
SELECT col_type_is('match_pairs', 'id', 'uuid');
SELECT col_is_pk('match_pairs', 'id');
SELECT col_has_default('match_pairs', 'id');
SELECT col_not_null('match_pairs', 'id');
SELECT col_type_is('match_pairs', 'event_id', 'uuid');
SELECT col_is_fk('match_pairs', 'event_id');
SELECT col_not_null('match_pairs', 'event_id');
SELECT col_type_is('match_pairs', 'user_lower_id', 'uuid');
SELECT col_is_fk('match_pairs', 'user_lower_id');
SELECT col_not_null('match_pairs', 'user_lower_id');
SELECT col_type_is('match_pairs', 'user_higher_id', 'uuid');
SELECT col_is_fk('match_pairs', 'user_higher_id');
SELECT col_not_null('match_pairs', 'user_higher_id');
SELECT col_type_is('match_pairs', 'matched_at', 'timestamp with time zone');
SELECT col_has_default('match_pairs', 'matched_at');
SELECT has_index('match_pairs', 'idx_match_pairs_event');
SELECT has_index('match_pairs', 'idx_match_pairs_users');

SELECT * FROM finish();
ROLLBACK;
