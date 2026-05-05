-- Drop Metabase 관련 테이블들. Metabase 가 minglit DB 를 자체 메타스토어로 사용한 흔적.
--
-- 배경:
--   - Metabase 가 활성 사용 중일 때 minglit Postgres 를 백엔드로 설정 → public 스키마에 자체 운영 데이터
--     (대시보드 정의, 사용자 세션, task history 등) 약 40개 테이블 자동 생성
--   - 마지막 task_history INSERT: 2026-04-18 (이 PR 시점 17일 전) — Metabase 비활성화됨
--   - DB 사이즈 488MB → Supabase Free 500MB 한도 92% 도달 → 정리 필요
--
-- 영향:
--   - 즉시 회수: ~29MB (488MB → 459MB 검증 완료)
--   - 회수 항목: task_history 17MB, metabase_field 8.7MB, 기타 ~40 테이블
--   - 향후 Metabase 재활성화 시 자체 init 으로 자동 재생성 (단 collection/dashboard/user 데이터 손실)
--
-- 실행 이력:
--   dev 환경: 2026-05-05 직접 SQL 로 이미 drop. 본 migration 은 main 환경 적용 + IaC 영속성 위함.
--   main 환경 deploy 시 IF EXISTS 로 멱등 (이미 없으면 NOOP).

DROP TABLE IF EXISTS
  -- Metabase 핵심 메타데이터
  public.task_history,
  public.metabase_field,
  public.metabase_table,
  public.metabase_database,
  public.metabase_fieldvalues,
  public.metabase_cluster_lock,
  public.metabase_field_user_settings,
  -- Metabase 내부 사용자/세션
  public.core_user,
  public.core_session,
  public.login_history,
  -- Metabase 권한 시스템
  public.permissions,
  public.permissions_group,
  public.permissions_group_membership,
  public.permissions_revision,
  public.data_permissions,
  -- Metabase 컬렉션/대시보드/카드
  public.collection,
  public.collection_bookmark,
  public.dashboard_bookmark,
  public.card_bookmark,
  public.action,
  public.model_index,
  public.model_index_value,
  public.dimension,
  public.native_query_snippet,
  -- Metabase 분석 객체
  public.metric,
  public.segment,
  public.timeline,
  public.timeline_event,
  -- Metabase 알림/공유
  public.pulse,
  public.pulse_card,
  public.pulse_channel,
  public.pulse_channel_recipient,
  public.user_parameter_value,
  -- Metabase 쿼리 로그/캐시
  public.query,
  public.query_execution,
  public.query_cache,
  public.field_usage,
  public.view_log,
  public.revision,
  -- Metabase 설정
  public.setting,
  -- Liquibase migration tracking (Metabase 의 schema 관리)
  public.databasechangelog,
  public.databasechangeloglock
CASCADE;
