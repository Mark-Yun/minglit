-- Fix #1413: seed.dev.sql 전환으로 dev_seed_bulk_users/partners RPC 불필요.
-- 이 RPCs는 prod DB에 존재해서는 안 되는 dev-only 코드였음 — 완전 제거.
-- Seeding은 이제 GitHub Actions에서 psql -f seed.dev.sql 로 직접 실행됨.

DROP FUNCTION IF EXISTS dev_seed_bulk_users(jsonb, text);
DROP FUNCTION IF EXISTS dev_seed_bulk_partners(jsonb, jsonb);
