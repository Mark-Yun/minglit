# Spec: 개인정보 보호

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs:
>   - [`privacy_page`](../../../../apps/mds/docs/public/specs/privacy_page/) — `/my/privacy` 본체 (3 state: Default / Loading / Error · 동의/약관/계정 3 섹션 + 탈퇴 진행 중 sub-variant)
> - Wireframe: [wireframe.html](./wireframe.html) — Phase 2 (#556) 인증 열람 권한 관리 wireframe (구형)
> - 마이그레이션 source: [ui-ux-design.md](./ui-ux-design.md) v1.0, 2026-03-28 (#556 기반) — Phase 2 의 원본 설계서

## CUJs

> Phase 1 (현재 구현됨) = Scenario 1·2·3. Phase 2 (#556 신규) = Scenario 4·5.

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 선택 동의 SwitchListTile 토글 | • `/my/privacy` 진입<br>• 제3자 제공 / 마케팅 / 위치 SwitchListTile 토글<br>• 즉시 user_consents update + UI 반영 | FR-1, FR-3 | NFR-1, NFR-2 |
| 1-2 | P0 | 토글 실패 시 원상복구 | • 토글 후 서버 응답 실패<br>• "동의 변경에 실패했습니다." SnackBar<br>• Switch 상태 서버 기준으로 자연스럽게 복구 (Fix #886) | FR-1, FR-2 | NFR-2 |
| 1-3 | P0 | 필수 동의 read-only 표시 | • 서비스 이용약관 / 개인정보 수집·이용 / 본인인증 정보<br>• ListTile (Switch 아님)<br>• statusText "동의됨" 또는 "미동의" (본인인증 미완) | FR-4 | NFR-1 |
| 2-1 | P0 | 동의 항목 본문 시트 열람 | • 필수 동의 ListTile 탭<br>• ConsentDetailSheet 가 아래에서 올라옴 (initialSize 0.82)<br>• 스크롤 + 닫기 | FR-5 | NFR-3 |
| 2-2 | P0 | 약관 보기 섹션 ListTile 탭 | • 서비스 이용약관 / 개인정보처리방침 / 위치정보 이용약관 탭<br>• ConsentDetailSheet 노출 | FR-5 | NFR-3 |
| 2-3 | P1 | 본인인증 미완 상태에서 본인인증 정보 탭 | • 본인인증 미완 상태<br>• "본인인증 정보" ListTile 탭 무반응 (chevron 미표시) | FR-6 | NFR-1 |
| 3-1 | P0 | 회원 탈퇴 시작 진입 | • "계정" 섹션 카드의 "회원 탈퇴 시작하기" TextButton 탭<br>• appCoordinator.startAccountDeletion() → DeletionReasonRoute push | FR-7 | NFR-1 |
| 3-2 | P0 | 탈퇴 진행 중 재진입 시 sub-variant | • 회원 탈퇴 신청 후 유예 기간 안에 재진입<br>• 카드 아이콘 hourglass_top<br>• 제목 "탈퇴 요청 진행 중"<br>• 보조 "유예 기간 안에는 다시 로그인해 계정을 복구할 수 있어요."<br>• 버튼 라벨 "탈퇴 진행 상태 보기" | FR-8 | NFR-1 |
| 4-1 | P1 | (Phase 2 · #556) 인증 열람 권한 목록 노출 | • `/my/privacy` 진입<br>• "인증 열람 현황" 섹션 (Phase 2 신규)<br>• 파트너별 그룹 카드 + 인증별 만료일 / D-day | FR-9, FR-10 | NFR-1, NFR-4 |
| 4-2 | P1 | (Phase 2) 만료 임박 / 만료됨 시각 분기 | • 만료 임박 30 일 이내: warning 톤 + ⚠️ "D-N 곧 만료됩니다"<br>• 만료됨: 그레이 톤, 접힌 섹션 (ExpansionTile) 으로 이동 | FR-11 | NFR-1 |
| 4-3 | P1 | (Phase 2) 빈 상태 (공유된 인증 없음) | • 활성 권한 0 건<br>• Empty State 표시 ("공유된 인증이 없습니다" + 안내문)<br>• "인증 열람 현황" 섹션 자체는 노출되지 않을 수도 있음 (Open Q) | FR-12 | NFR-1 |
| 5-1 | P1 | (Phase 2) 권한 철회 확인 다이얼로그 | • 권한 카드 "권한 철회" 탭<br>• 2 단계 확인 다이얼로그<br>• "취소" / "철회하기" | FR-13, FR-14 | NFR-1 |
| 5-2 | P1 | (Phase 2) 권한 철회 성공 후 SnackBar + 목록 갱신 | • "철회하기" 탭 → DELETE partner_verified_users<br>• "권한이 철회되었습니다" SnackBar (3 초)<br>• 목록 갱신, 파트너의 마지막 인증이면 파트너 카드 사라짐 | FR-13, FR-15 | NFR-2 |
| 6-1 | P0 | Loading state — 동의 정보 가져오는 중 | • 진입 직후 / 다시 조회 시<br>• Body 영역 중앙에 MinglitCircularProgressIndicator<br>• AppBar 는 normal 노출 | FR-16 | NFR-1 |
| 6-2 | P0 | Error state — 동의 정보 로드 실패 | • 첫 진입에서 fetch 실패<br>• Body 영역 중앙에 "동의 정보를 불러올 수 없습니다." (bodyLarge · color-text-secondary)<br>• 재시도 버튼 없음 (Open Q — 후속 보강 후보) | FR-17 | NFR-1 |

## Functional Requirements

- **FR-1**: 선택 동의 (제3자 제공 · 마케팅 · 위치) 는 SwitchListTile 로 즉시 토글 가능. consentControllerProvider.toggleConsent(type, consented:) 호출 → user_consents update.
- **FR-2**: 토글 서버 응답 실패 시 (1) SnackBar "동의 변경에 실패했습니다. 다시 시도해주세요." 노출, (2) 해당 row invalidate → 서버 기준 상태로 자연스럽게 복구 (Fix #886).
- **FR-3**: Switch on 시 user_consents 의 해당 row 가 consented=true · consented_at=now 으로 set. off 시 withdrawn_at=now.
- **FR-4**: 필수 동의 (서비스 이용약관 · 개인정보 수집·이용 · 본인인증 정보) 는 ListTile read-only. trailing 에 statusText ("동의됨" / "미동의") + chevron_right.
- **FR-5**: ListTile / 약관 보기 ListTile 탭 시 showConsentDetailSheet(content) → ConsentDetailSheet (DraggableScrollableSheet · initialChildSize 0.82) 표시. 닫기 시 동의 상태 변경 없음.
- **FR-6**: 본인인증 미완 상태에서는 "본인인증 정보" 항목 trailing chevron 미표시 + 탭 무반응. 인증 완료 후에만 본문 시트 열림.
- **FR-7**: "계정" 섹션 "회원 탈퇴 시작하기" TextButton 탭 시 appCoordinator.startAccountDeletion() → DeletionReasonRoute push.
- **FR-8**: 탈퇴 진행 중 (`accountDeletionControllerProvider.DeletionStatus.isPending`) 재진입 시 "계정" 섹션 카드 변형 — leading hourglass_top · title "탈퇴 요청 진행 중" · subtitle "유예 기간 안에는 다시 로그인해 계정을 복구할 수 있어요." · 버튼 "탈퇴 진행 상태 보기".
- **FR-9** (Phase 2): "인증 열람 현황" 섹션 신규 — 상단 요약 카드 (활성 N · 만료 임박 N · 안심 메시지) + 파트너별 그룹 카드 (브랜드 + 승인 N 건 + 인증 카드 N 개).
- **FR-10** (Phase 2): verificationRepository.getMyVerificationPermissions() 가 partner_verified_users + partners + verifications JOIN 결과를 파트너 그룹화 + status (active / expiring_soon / expired) 컬럼 포함하여 반환.
- **FR-11** (Phase 2): D-day 컬러 — D-31+ onSurfaceVariant · D-30~D-8 warning amber · D-7~D-1 error red · D-0 이하 outline grey (만료됨, 접힌 섹션).
- **FR-12** (Phase 2): 활성 권한 0 건이면 Empty State 표시 — "공유된 인증이 없습니다" + 안내문 ("이벤트 참여 시 파트너에게 인증을 제출하면 이곳에서 열람 권한을 관리할 수 있습니다.").
- **FR-13** (Phase 2): "권한 철회" 버튼 탭 시 2 단계 확인 다이얼로그 — title "권한을 철회하시겠습니까?" · 본문 "{파트너명}의 {인증명} 열람 권한을 철회합니다." · "⚠️ 철회 후에는 되돌릴 수 없습니다." · 버튼 "취소" / "철회하기".
- **FR-14** (Phase 2): "철회하기" 탭 시 revokeVerificationPermission(partnerId, verificationId) 호출 → Edge Function(user-revoke-verification-permission)을 통해 서버에서 partner_verified_users 변경 처리. 클라이언트 RLS는 READ-only 유지 — DELETE는 EF service_role 경유.
- **FR-15** (Phase 2): 철회 성공 시 (1) "권한이 철회되었습니다" SnackBar (3 초), (2) 목록 invalidate + 요약 카운트 갱신. 파트너의 마지막 인증이면 파트너 카드 자체 사라짐.
- **FR-16**: Loading state — body 영역 중앙에 MinglitCircularProgressIndicator. AppBar 는 평소대로 노출. 뒤로 가기 정상 동작.
- **FR-17**: Error state (첫 진입 fetch 실패) — body 영역 중앙에 Padding(spacing-large) > Text("동의 정보를 불러올 수 없습니다.", bodyLarge, color-text-secondary). 별도 재시도 버튼 없음. 이미 한 번 본문이 노출된 후 fetch 실패는 SnackBar 만 (본문 유지).

## Non-Functional Requirements

- **NFR-1**: 화면 진입 → first paint 200ms 이내 (에뮬레이터 baseline, p50). 캐시 hit 시 즉시 노출.
- **NFR-2**: Switch 토글 → 서버 응답 → UI 반영 / 원상복구 1.5 초 이내 (모바일 4G baseline, p50). 실패 시 즉시 SnackBar.
- **NFR-3**: ConsentDetailSheet 노출 → 본문 fully visible 350ms 이내 (MinglitAnimation.medium). 시트 본문은 static const 라 fetch 없음.
- **NFR-4** (Phase 2): 인증 열람 권한 목록 조회 → 렌더링 800ms 이내 (10 개 파트너 baseline, p50, mobile 4G).
- **NFR-5**: 접근성 — 모든 SwitchListTile / ListTile 최소 터치 영역 48dp + semanticsLabel. 다크 모드 자동 전환 (Fix #1157 보존).
- **NFR-6**: 동의 변경 이력 최소 2 년 보존 (개인정보보호법 시행령) — DB 레벨 (본 spec 의 행동은 아님).

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | Switch 빠르게 여러 번 탭 (debounce) | 마지막 탭 상태로 1 회만 요청. 중간 상태 race 없음 |
| 1-2 | 토글 실패 + 동시에 화면 이탈 | SnackBar 미표시 (화면 사라짐), 다음 진입 시 서버 기준 정상 상태 |
| 2-1 | 본문 시트 떠 있는 동안 탭 → 다른 항목 | 현재 시트 닫고 새 시트 열림 (showConsentDetailSheet 단일 인스턴스) |
| 2-3 | 본인인증 미완 + 본인인증 정보 ListTile 탭 | 탭 무반응 (chevron 미표시). 인증 완료 후 다시 들어와야 함 |
| 3-1 | 탈퇴 wizard 진입 후 cancel 으로 복귀 | "계정" 섹션은 기존 상태 (sub-variant 아님). 탈퇴 신청 X 상태 |
| 3-2 | 탈퇴 신청 후 유예 기간 지난 후 재진입 | 자동 탈퇴 완료 — 사용자는 로그인 자체가 안 됨 (이 화면 도달 X) |
| 4-1 (P2) | 활성 권한 + 만료 권한 혼재 | 활성 권한 우선 노출, 만료 권한은 접힌 섹션 (ExpansionTile) |
| 4-2 (P2) | 권한 0 건 + 신규 인증 제출 직후 | 새 권한이 목록에 즉시 노출 (invalidate provider) |
| 4-3 (P2) | 활성 0 + 만료 N 건만 있는 경우 | Empty State 대신 만료 섹션만 노출 (Open Q — 정책 결정) |
| 5-1 (P2) | revoke 도중 네트워크 끊김 | SnackBar + retry 1 회. 실패 지속 시 사용자에게 재시도 안내 |
| 5-2 (P2) | revoke 후 진행 중 이벤트 영향 | 별도 안내 알림 / 소급 적용 정책 미정 (Open Q — signup-consent 와 동일 미해결) |
| 6-1 | Loading 중 사용자 입력 | 입력 차단 (body 가 spinner 만). AppBar back 정상 동작 |
| 6-2 | Error 후 다시 진입 | 자동 재시도 — 이번엔 성공하면 본문 노출 |
| — | 비로그인 deep-link `/my/privacy` | 라우터가 `/login` 으로 redirect. 본 페이지 도달 X |

## Open Questions

- [ ] **(Phase 1) Error state 재시도 버튼 부재** — 현재는 뒤로 가기 → 재진입만. 명시적 "다시 시도" 버튼 추가 가치 검토
- [ ] **(Phase 1 → 2 결합) 본 페이지의 4 번째 섹션 (인증 열람 현황) 노출 위치** — "동의 현황" 위 / 아래 / 별도 페이지? 정보 밀도 trade-off
- [ ] **(Phase 2) 빈 상태 vs 만료-only 상태 분기** — 활성 0 + 만료 N 인 경우 Empty State 보여줄지 만료 섹션만 보여줄지
- [ ] **(Phase 2) revoke 후 진행 중 이벤트** — 소급 적용 X (현재 가정) vs 안내 알림 → 법무 컨펌 필요 (signup-consent #3-2 와 동일 미해결)
- [ ] **(Phase 2) 만료된 권한 DB 보존** — hard delete (즉시 삭제) vs soft expire (감사용 보관) 정책 결정
- [ ] **(Phase 2) RLS DELETE 정책 텍스트** — `partner_verified_users` USING + WITH CHECK 정확한 식 검토 (auth.uid() = user_id)

---

## 화면 구성 (참고)

> MDS spec [`privacy_page`](../../../../apps/mds/docs/public/specs/privacy_page/) 이 SSoT (Phase 1). Phase 2 는 본 폴더의 [`ui-ux-design.md`](./ui-ux-design.md) 의 wireframe 참조.

### 화면 1: PrivacyPage (`/my/privacy`)

**표시 시점**: MyPage → "개인정보 및 보안 → 개인정보" 타일 탭.

**레이아웃** (Phase 1 — 현재 구현):

```
┌──────────────────────────────────┐
│  ←  개인정보                      │ ← AppBar (centerTitle false)
├──────────────────────────────────┤
│  동의 현황                        │ ← SectionHeader (titleSmall · onSurfaceVariant)
│  서비스 이용약관      동의됨  ⌃   │ ← ReadOnlyConsentTile
│  개인정보 수집·이용   동의됨  ⌃   │
│  제3자 제공 동의               □  │ ← SwitchListTile
│  마케팅 정보 수신              □  │
│  위치정보 이용 동의            □  │
│  본인인증 정보       동의됨  ⌃   │ ← ReadOnlyConsentTile (또는 미동의)
│  ────────────────────────────── │ ← Divider 1px
│  약관 보기                       │
│  서비스 이용약관              ⌃   │ ← ListTile + chevron
│  개인정보처리방침             ⌃   │
│  위치정보 이용약관            ⌃   │
│  ────────────────────────────── │
│  계정                            │
│  ┌────────────────────────────┐ │
│  │ ⛔ 회원 탈퇴 (color-error)   │ │ ← Card (radius-card · margin H = screenEdge)
│  │   안내 문구                  │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │     회원 탈퇴 시작하기        │ │ ← width:∞ TextButton (primary)
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

**Phase 2 추가 섹션** (#556 기반, ui-ux-design.md 의 wireframe 3.1):

```
인증 열람 현황                       ← Phase 2 신규 SectionHeader
┌────────────────────────────────┐
│ 🛡  내 인증 열람 현황            │ ← 요약 카드
│ 활성 권한  3개                   │
│ 만료 예정  1개 (30일 이내)        │
│ ℹ️ 모든 열람 권한은 만료일이      │
│   설정되어 자동 종료됩니다         │
└────────────────────────────────┘
🏢 밍글파티 · 승인 2건                ← 파트너 그룹 카드
  ┌──────────────────────────────┐
  │ 💼 직장 인증                  │
  │ 승인일 2026.01.15             │
  │ 만료일 2026.07.15  D-109      │
  │              [권한 철회]      │ ← Phase 2 액션
  └──────────────────────────────┘
  ┌──────────────────────────────┐
  │ 🎓 학력 인증                  │
  │ ... (D-day 컬러 분기)         │
  └──────────────────────────────┘

만료된 권한 (2건)              ▼   ← ExpansionTile (접힌 상태 default)
```

### State 변형 (MDS spec 요약 · Phase 1)

| State | 조건 | 변화 |
|-------|------|------|
| 1. Default 🎯 baseline | 동의 정보 로드 완료 | 3 섹션 모두 노출 (동의 / 약관 / 계정) |
| 1-sub. 탈퇴 진행 중 | accountDeletionController.isPending = true | "계정" 카드 변형: hourglass icon · "탈퇴 요청 진행 중" · 버튼 "탈퇴 진행 상태 보기" |
| 2. Loading | fetch 진행 중 | body 중앙 MinglitCircularProgressIndicator. AppBar normal |
| 3. Error | 첫 fetch 실패 | body 중앙 "동의 정보를 불러올 수 없습니다." · 재시도 버튼 X |

### Phase 2 추가 state (#556)

| State | 조건 | 변화 |
|-------|------|------|
| 4. (P2) Empty | 활성 권한 0 건 | "공유된 인증이 없습니다" + 안내문 |
| 5. (P2) revoke 다이얼로그 | "권한 철회" 탭 후 | MinglitAlert overlay · 2-line 안내 · "취소" / "철회하기" 버튼 |
| 6. (P2) revoke 성공 SnackBar | DELETE 성공 후 | "권한이 철회되었습니다" 3 초 · 자동 dismiss |

### 동의 항목 정의 (Phase 1 · ConsentType)

| consent_key | 필수/선택 | UI | 본문 fetch |
|-------------|----------|----|----|
| `terms_of_service` | 필수 | ReadOnlyConsentTile + 본문 시트 | static const |
| `privacy_collection` | 필수 | ReadOnlyConsentTile + 본문 시트 | static const |
| `third_party_provision` | 선택 | SwitchListTile + 본문 시트 | static const |
| `marketing_consent` | 선택 | SwitchListTile | (선택) |
| `location_consent` | 선택 | SwitchListTile + 본문 시트 | static const |
| `identity_verification` | 필수 | ReadOnlyConsentTile (statusText: 동의됨/미동의) | static const (인증 완료 시만 시트 open) |

### Phase 2 데이터 정의 (#556)

| 항목 | source | 설명 |
|------|--------|------|
| 활성 권한 N | partner_verified_users WHERE valid_until > now() AND user_id = auth.uid() | count |
| 만료 임박 N | 동 + valid_until ≤ now() + 30 days | count |
| 인증 카테고리 아이콘 | verifications.category | 💼 career · 🎓 academic · 💰 asset · 🚗 vehicle · 💍 marriage · 📋 etc |
| status 컬럼 | CASE valid_until vs now | active / expiring_soon / expired |
| revoke API | Edge Function (user-revoke-verification-permission) | service_role 로 partner_verified_users 변경/감사 |
