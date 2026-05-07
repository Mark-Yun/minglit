---
source_url: https://github.com/Mark-Yun/minglit/issues/2167
captured_at: 2026-05-05
issue_number: 2167
state: open
labels: [audit-report]
author: Mark-Yun
title: "🔍 QA Audit Report — 2026-05-05: Wizard 검증 P1 클러스터(4건) + Navigation contract 갭 + catalog DEPRECATED visibility"
---

# 🔍 QA Audit Report — 2026-05-05: Wizard 검증 P1 클러스터(4건) + Navigation contract 갭 + catalog DEPRECATED visibility

> Issue #2167 · open · created 2026-05-05 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2167

## Body

Scheduler: audit-qa-claude-subagents

## TL;DR

지난 1주일 트렌드 3개:

1. **Partner Onboarding Wizard 검증 P1 클러스터 (4건, 1일 만에)** — `validateStep()` 로직은 있지만 **UI Next 버튼이 그것을 호출하지 않아** 빈 폼으로 다음 스텝 진행 가능. PR #2165가 8개 위젯 테스트로 픽스 중. **재발 방지를 위해 wizard 패턴을 `test-strategy.md`에 등재 필요**.
2. **Navigation contract 갭** — `app_routes_snapshot_test.dart`가 route 존재성은 보장하지만, **"UI 요소 탭 → 의도된 route 도달"** 컨트랙트는 미커버. 같은 클래스 버그 2건: #2074 (closed), #2137 (open).
3. **Test catalog DEPRECATED 항목이 runtime QA 워커를 트립** — 작은 운영 부채. `app-user-smoke.md` U-S20의 strikethrough markup이 가시성 부족 → #2138 false-positive 버그 리포트 발생.

---

## 1. Wizard 검증 P1 클러스터 — pattern enshrining 필요

### 트렌드 근거
2026-05-04 하루에 동일 영역(partner onboarding wizard) P1 4건 동시 보고:

| 이슈 | 증상 | 커버되지 않은 단위 |
|------|------|----------|
| #2130 (closed via #2159) | jumpToPage 누락 → draft 복원 시 title/content desync | (이미 회귀 테스트 추가됨) |
| #2161 (open) | Step 2 "이전" 버튼 비활성화 / "다음" 검증 누락 | "이전" 버튼 enabled 위젯 테스트 |
| #2162 (open) | Step 3 빈 필드에서 "다음" 활성화 | Step 3 Next × validateStep(2) 위젯 테스트 |
| #2163 (open) | Step 4 빈 첨부에서 "다음" 활성화 | Step 4 Next × validateStep(3) 위젯 테스트 |

### Root cause
- `apps/app_partner/lib/src/features/onboarding/partner_apply_validation.dart:4` — `validateStep(int step)` 로직 정상.
- 단위 테스트(`partner_apply_validation_test.dart`)는 로직만 검증.
- 위젯 테스트(`partner_apply_page_test.dart`, `cuj_partner_apply_wizard_test.dart`)는 Step 0/1/4의 "다음"/"신청하기" 버튼만 검증. **Step 2, 3에는 button × validateStep widget test 없음**.

### 현황
PR #2165가 픽스 + 8개 회귀 테스트 추가 중. `partner_apply_page.dart`의 Next 버튼이 `validateStep(currentStep)`을 게이트하도록 수정. **이 PR이 머지되면 partner onboarding 자체는 안전**.

### 제안 (P2)
**`docs/qa/test-strategy.md`에 "Wizard step Next button widget test" 패턴 등재** — 미래의 wizard flow (signup-consent, event-edit 등)에서 동일 갭 재발 방지.

구체적 추가 항목 (Layer 2a Widget flow test 섹션):

```markdown
### Wizard flow 패턴 — 필수 위젯 테스트 체크리스트

다단계 wizard(2 step 이상) 신규 추가 시 다음 위젯 테스트 필수:

1. 각 step에서 "다음" 버튼이 `validateStep(currentStep)` false일 때 disabled (`onPressed == null`)
2. 각 step에서 "이전" 버튼이 step > 0일 때 enabled
3. 마지막 step "신청하기/제출" 버튼이 `validateAll()` false일 때 disabled
4. Draft 복원 시 PageView가 `currentStep`으로 즉시(jumpToPage) 이동

레퍼런스 구현: `apps/app_partner/test/src/features/onboarding/cuj_partner_apply_wizard_test.dart` (TC-P01-001/002/003/004) + PR #2165 후속.
```

대상 SWE 워커: `needs-qa` (test-strategy.md 업데이트는 QA 영역). 내가 다음 사이클에 직접 가능.

---

## 2. Navigation contract 갭 — UI element → route binding 미커버

### 트렌드 근거

| 이슈 | UI 요소 | 의도 route | 실제 동작 |
|------|---------|----------|-----------|
| #2074 (closed via #2091) | 파트너 앱 More 시트 "계좌 관리" 메뉴 | `/account` | `/partner-application` |
| #2137 (open) | 파트너 상세 "더 보기" | `/partners/:id/events` | "Unknown Route" → MyPage fallback |

두 건 모두 **route는 존재**(snapshot test 통과)했지만 **UI 요소가 잘못된 destination을 가리킴**. 현재 테스트 풀이 catch 못함.

### 갭 분석

`apps/app_user/test/src/routing/app_routes_snapshot_test.dart`는 GoRouter tree의 path 목록을 snapshot으로 잠금. 신규 route 추가/삭제는 감지하지만 **각 화면의 navigation entry point가 올바른 route를 호출하는지는 검증 안 함**.

```dart
// 현재 갖고 있음 (snapshot)
expect(collectAllRoutePaths($appRoutes), unorderedEquals([...]))

// 부족함 (UI binding contract)
testWidgets('파트너 상세 "더 보기" 탭 → /partners/:id/events 진입', () { ... })
```

### 제안 (P2)

**고-traffic 진입점 위젯에 navigation contract test 추가** (전체 화면 아님, 빈도 높은 곳만):

| 위젯 | 검증할 navigation contract | 우선순위 |
|------|---------------------------|---------|
| `PartnerDetailPage` "더 보기" 버튼 | `/partners/:id/events` push | P2 (#2137 회귀 가드) |
| `app_partner` MoreSheet "계좌 관리" | 정확한 settlement route push | P2 (#2074 회귀 가드) |
| `MyPage` 모든 메뉴 항목 | 각각의 의도 route push | P3 |
| `app_partner` MoreSheet 모든 항목 | 각각의 의도 route push | P3 |

구현 패턴 (mocktail GoRouter mock):
```dart
testWidgets('PartnerDetailPage "더 보기" navigates to /partners/:id/events', (tester) async {
  final mockRouter = MockGoRouter();
  await tester.pumpWidget(...);
  await tester.tap(find.text('더 보기'));
  verify(() => mockRouter.push('/partners/test-id/events')).called(1);
});
```

대상: `needs-swe` (구현). 내가 트래커 이슈 분리 파일링.

---

## 3. Test catalog DEPRECATED 항목 visibility — 운영 부채

### 트렌드 근거

`docs/qa/test-cases/app-user-smoke.md:59` U-S20:
```markdown
| U-S20 | ~~개발 도구~~ | ~~`/dev`~~ | ~~`UserDevMap`~~ | — | — | — | **DEPRECATED** — PR #274 ... |
```

Strikethrough(`~~`) markup만으로 marking되어 있고, **runtime-qa 워커가 이를 트립해서 #2138 (P3 bug-report)을 파일링**. 워커는 strikethrough를 신호로 인식하지 않고 `/dev` 경로를 테스트 대상으로 봄.

### 영향
- 낮음 (P3 노이즈 버그 1건)
- 하지만 미래에 같은 패턴 deprecation이 나오면 반복

### 제안 (P3)

옵션 A (preferred): catalog에서 행 자체 삭제 + git history에 maintenance ledger 코멘트.
옵션 B: 행 유지 시 첫 컬럼 ID를 `~~U-S20~~ DEPRECATED`로 명확히 하고, 본문 첫 줄에 `> ⚠️ runtime-qa 워커는 이 행을 무시할 것` 주석 명시.

내가 다음 사이클에 직접 옵션 A로 정리 가능 (`docs/qa/` SSOT 책임).

---

## 직접 처리 가능 항목 (다음 사이클)

- [ ] `docs/qa/test-strategy.md`에 Wizard 패턴 체크리스트 추가 (Section 1 제안)
- [ ] `docs/qa/test-cases/app-user-smoke.md` U-S20 DEPRECATED 행 정리 (Section 3 제안)

## 분리 파일링 (needs-swe 트래커)

- [ ] Navigation contract widget tests — PartnerDetailPage "더 보기" + MoreSheet 항목 (Section 2)

## 무관 발견

- 라우팅 스냅샷 테스트(`app_routes_snapshot_test.dart`)와 routing-test-plan.md(2026-04 작성)는 잘 갖춰져 있다 — Layer 1은 견고. 갭은 Layer 2(UI→route binding)에만 있음.
- 위저드 단위 테스트 풀은 `validateStep`/`validateAll`/`canProceed`/`submit` 모두 견고. 갭은 widget × button 표면.
- PR #2165가 머지되면 wizard 클러스터는 closed. 이 보고서는 **재발 방지 패턴 정착**에 초점.
