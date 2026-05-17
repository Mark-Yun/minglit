# integration_test

Flutter integration test 의 entry point. 에뮬레이터(또는 디바이스)에서 실제 앱을 build 하여 실행하는 테스트들을 둔다.

## 하위 폴더

- [mds-emulator-render/](./mds-emulator-render/) — MDS spec 화면을 실제 앱으로 렌더링 → PNG 캡처. MDS HTML mockup PNG (`apps/mds/docs/public/specs/<screen>/state_*.png`) 와 비교 대상.

## 관련

- `test/integration/cuj_*.dart` — Critical User Journey (CUJ) 통합 테스트. 별도 위치, 실제 앱 동작 검증 위주.
- `patrol_test/` — Patrol 기반 E2E. native 자동화 필요한 케이스 (kakao 로그인, 결제 등).
- `test_driver/` — Flutter drive entry. 워크플로우별 driver (`spec_walker_driver.dart` 등).

## 워크플로우 페어

- [sync-mds-mockups](../../.github/workflows/sync-mds-mockups.yml) — MDS HTML 디자인 → mockup PNG
- (예정) `mds-emulator-render.yml` — 본 폴더 테스트 실행 → 실제 PNG

두 워크플로우의 PNG 비교가 GUI drift 감지의 1차 신호.

---
_Reviewed: 2026-05-17 22:32_
