BEGIN;
SELECT plan(43);

-- minglit_files
SELECT has_table('minglit_files');
SELECT has_column('minglit_files', 'id');
SELECT has_column('minglit_files', 'storage_object_id');
SELECT has_column('minglit_files', 'bucket_id');
SELECT has_column('minglit_files', 'file_path');
SELECT has_column('minglit_files', 'owner_id');
SELECT has_column('minglit_files', 'created_at');
SELECT col_type_is('minglit_files', 'id', 'uuid');
SELECT col_is_pk('minglit_files', 'id');
SELECT col_has_default('minglit_files', 'id');
SELECT col_not_null('minglit_files', 'id');
SELECT col_type_is('minglit_files', 'storage_object_id', 'uuid');
SELECT col_is_fk('minglit_files', 'storage_object_id');
SELECT col_not_null('minglit_files', 'storage_object_id');
SELECT col_not_null('minglit_files', 'bucket_id');
SELECT col_not_null('minglit_files', 'file_path');
SELECT col_type_is('minglit_files', 'owner_id', 'uuid');
SELECT col_is_fk('minglit_files', 'owner_id');
SELECT col_not_null('minglit_files', 'owner_id');
SELECT col_type_is('minglit_files', 'created_at', 'timestamp with time zone');
SELECT col_has_default('minglit_files', 'created_at');
SELECT has_index('minglit_files', 'idx_minglit_files_owner');
SELECT has_index('minglit_files', 'idx_minglit_files_path');

-- file_access_grants
SELECT has_table('file_access_grants');
SELECT has_column('file_access_grants', 'id');
SELECT has_column('file_access_grants', 'file_id');
SELECT has_column('file_access_grants', 'viewer_id');
SELECT has_column('file_access_grants', 'expires_at');
SELECT has_column('file_access_grants', 'created_at');
SELECT col_type_is('file_access_grants', 'id', 'uuid');
SELECT col_is_pk('file_access_grants', 'id');
SELECT col_has_default('file_access_grants', 'id');
SELECT col_not_null('file_access_grants', 'id');
SELECT col_type_is('file_access_grants', 'file_id', 'uuid');
SELECT col_is_fk('file_access_grants', 'file_id');
SELECT col_not_null('file_access_grants', 'file_id');
SELECT col_type_is('file_access_grants', 'viewer_id', 'uuid');
SELECT col_is_fk('file_access_grants', 'viewer_id');
SELECT col_not_null('file_access_grants', 'viewer_id');
SELECT col_type_is('file_access_grants', 'expires_at', 'timestamp with time zone');
SELECT col_type_is('file_access_grants', 'created_at', 'timestamp with time zone');
SELECT col_has_default('file_access_grants', 'created_at');
SELECT has_index('file_access_grants', 'idx_file_grants_file_viewer');

SELECT * FROM finish();
ROLLBACK;
