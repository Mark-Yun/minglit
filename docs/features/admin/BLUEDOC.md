# Admin Features

관리자 도메인 — 내부 운영 도구. Flutter user/partner 앱이 아니라 향후 별도 Next.js admin console 에서 구현한다.

## 구현 상태

- 전용 Next.js admin app 은 아직 없다. canonical target 은 `apps/admin_web/` 이며, scaffold 전 상태다.
- 현재 구현된 `apps/app_partner/lib/src/features/admin/` 은 파트너 신청 심사 보조 화면이며, admin-dashboard PRD 의 대체 구현이 아니다.

## 포함된 피쳐

- [admin-dashboard](./admin-dashboard/) — 관리자 대시보드
- [statistics-tools](./statistics-tools/) — 통계/분석 도구

## 리포트

- [FEATURE_REPORT.md](./FEATURE_REPORT.md) — FRESH_DOC cycle 로 주기적 갱신

## 관련 컨벤션

- [features BLUEDOC](../BLUEDOC.md) — feature 정의 및 분류 기준

---
_Reviewed: 2026-06-04 22:19_
