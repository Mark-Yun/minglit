# mds-emulator-render

MDS spec 의 각 화면을 실제 Flutter 앱으로 에뮬레이터에서 렌더링하여 PNG 캡처. 결과는 `docs/infra/mds-emulator-render/<screen>/state-*.png` 로, MDS HTML 디자인 (`apps/mds/docs/public/specs/<screen>/state_*.png`, `sync-mds-mockups.yml` 생성) 과 1:1 비교 대상.

## 왜 있나

이전 alchemist 골든 테스트가 실제 UI defect 를 못 잡았다 (블록 폰트, 실 viewport 부재, 실제 navigation 누락). 에뮬레이터 위 mock 주입 렌더링이 동일 결정성을 유지하면서 실 폰트·viewport·전환을 모두 잡는다.

## 트리거

현재는 **수동** (`flutter drive ...`). 후속 PR 에서 `monitor-mds-render-coverage.yml` (daily cron) 이 자동 실행 + 100% 미만 시 GitHub Issue 생성 예정.

## 빠른 실행 (단일 화면)

```bash
cd apps/app_user                        # ← cwd 필수 (driver 가 상대경로 사용)
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
flutter drive \
  --driver=test_driver/mds_emulator_render_driver.dart \
  --target=integration_test/mds-emulator-render/<screen>/<screen>_test.dart \
  --flavor dev \
  --dart-define-from-file=../../minglit_env/dev/flutter.env \
  -d <device>
```

## 산출물 (Phase 1 — 현재 구현됨)

| 산출물 | 위치 |
|--------|------|
| state PNG | `docs/infra/mds-emulator-render/<screen>/state-*.png` |

Phase 2 (TODO, follow-up PR) — `_manifest.yaml`, coverage report, scaffold 결과는 [architecture.md](./architecture.md) 의 구현 상태 표 참고.

## 등록된 화면 (카탈로그 완료)

| 화면 | states |
|------|--------|
| `auth_callback_page` | loading · loading-dark |
| `blocked_partners_page` | loading · empty · with-partners · dark |
| `deletion_complete_page` | default · dark |
| `deletion_info_page` | no-reason · with-reason |
| `deletion_reason_page` | initial · dark |
| `deletion_verify_page` | email-user · social-user · dark |
| `home_page` | default · guest · loading · feed-empty · error |
| `identity_verification_screen` | loading · consent-sheet · error-retry · dark |
| `login_page` | 기본 |
| `my_tickets_page` | active-banners · empty · logged-out |
| `notification_list_screen` | loaded · empty |
| `notification_settings_screen` | default |
| `privacy_page` | loading · loaded · dark |
| `search_page` | idle · results · empty |
| `event_now_bar` | waiting · check-in-ready · checked-in · matching · results · ended · offline |
| `event_ongoing_banner` | 8 phases + dark |
| `signup_consent_page` | loading · default · required-only · all · dark |
| `ticket_qr_screen` | with-token · not-found · dark |

## 폴더 컨벤션

MDS spec 디렉토리명과 동일 (per-screen, snake_case). 화면당 `builder.dart` + `<screen>_test.dart` 2 파일 (`home_page/` 참고).

## 새 화면 추가

`home_page/` 복제 → 빌더의 fluent 메서드 + catalog state list 수정. 패턴 상세: [architecture.md](./architecture.md).

## 관련

- [architecture.md](./architecture.md) — 설계 + 구현 상태 표
- [상위 BLUEDOC](../BLUEDOC.md) · 페어 워크플로우: `sync-mds-mockups.yml` (디자인 PNG)

---
_Reviewed: 2026-05-27 14:40_
