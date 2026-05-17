# PRD: 회원가입 동의 (Signup Consent)

## Summary

신규 OAuth 유저에게 명시적 약관 동의 UI 제공 + 동의 이력 DB 기록. 본인인증(CI/DI) 시점 별도 동의. 사후 변경 가능한 선택 동의(마케팅·제3자 제공) 관리 페이지 제공. 법률 감사 [High] 이슈(#747) 해결.

## Motivation / Problem to Solve

- 법률/개인정보보호 감사(#747)에서 [High] 이슈로 지적: "회원가입 시 명시적 동의 수집 UI 없음"
- 현재 OAuth 로그인 후 바로 앱 접근 가능 — 동의 수집 절차 부재
- CI/DI 수집(본인인증) 시에도 별도 동의 절차 없음
- 개인정보보호법 제15조 / 제17조 / 제22조 / 제24조 위반

## Goals

### Target Users

- **신규 유저**: 최초 OAuth 로그인 (회원가입 동의)
- **모든 유저**: 본인인증 수행 시 (CI/DI 동의)
- **모든 유저**: 선택 동의 사후 변경 시 (마케팅·제3자 제공)

### Key Goals

- **P0**: 필수 동의 3종(서비스 약관, 개인정보 수집, 만 14세) 명시적 수집 + DB 이력
- **P0**: 선택 동의(제3자 제공, 마케팅) 거부 시에도 서비스 이용 가능
- **P0**: CI/DI 수집 시 명시적 동의 (개인정보보호법 제24조)
- **P1**: 사후 동의 관리 (마케팅 토글, 제3자 제공 철회)
- **P1**: 점진적 동의 — 마케팅은 가입 시 필수 아님, 필요 시점 별도 요청

### Non-Goals

- 약관 버저닝 / 재동의 플로우 (별도 PR)
- 외국어 약관
- 탈퇴 시 동의 이력 별도 보관 테이블 (추후)

## Product Principles

1. **필수/선택 분리**: 필수 동의만으로 서비스 이용 가능. 선택 거부 시 불이익 없음
2. **명시적 동의**: 사전 체크(pre-checked) 금지. 사용자가 직접 탭/체크
3. **동의 이력 추적**: 언제·어떤 버전 약관에 동의했는지 DB 기록 (최소 2년 보존)
4. **점진적 동의 (Progressive Consent)**: 모든 동의를 한 화면에 몰아넣지 않고, 필요 시점에 요청

## Technical Approach

- 화면 3개: SignupConsentScreen / IdentityVerificationConsentSheet / PrivacyManagementPage
- 저장: `user_consents` 테이블 (user_id, consent_key, policy_version, consented_at, withdrawn_at)
- 약관 본문: 기존 `policies` 테이블 (key, version, value JSON)
- 가드: 라우터 redirect — 필수 동의 미완료 시 SignupConsentScreen 강제 진입

## User Journey

### Scenario 1: 신규 가입 약관 동의 (CUJ 1-x)

신규 OAuth 유저가 약관 동의 화면을 보고, 필수 3종 + 선택 항목 검토 후 가입을 완료한다.

### Scenario 2: 본인인증 CI/DI 동의 (CUJ 2-x)

유저가 본인인증을 시작할 때, CI/DI 수집·이용 동의 바텀시트가 표시되고 동의 후 Portone 인증으로 진행한다.

### Scenario 3: 사후 동의 관리 (CUJ 3-x)

유저가 MyPage → 개인정보 설정에서 마케팅·제3자 제공 동의를 토글로 변경한다.

## Data Flow

### Scenario 1

OAuth callback → 라우터 가드 (필수 동의 검사) → SignupConsentScreen → 동의 저장 (user_consents bulk upsert) → HomePage 진입

### Scenario 2

`/certification` → "본인인증 시작" 탭 → IdentityVerificationConsentSheet → 동의 저장 → Portone 호출

### Scenario 3

`/my/privacy` → 토글 변경 → user_consents 해당 row update (consented + withdrawn_at)

## KPIs / Success Metrics

- **동의 완료율** ≥ 95% (이탈률 < 5%)
- **선택 동의율** (마케팅): baseline 측정 → 추후 progressive consent 효과 비교
- **약관 화면 평균 체류시간**: 전문 읽음 여부 proxy
- **법률 감사 통과**: 차기 감사에서 본 이슈 close

## Launch Strategy

추후 stat-sig A/B — 점진적 동의 vs 일괄 동의 비교, 약관 화면 카피 variant.

## Legal Basis

| 근거 | 내용 |
|------|------|
| 개인정보보호법 제15조 | 수집·이용 동의 |
| 개인정보보호법 제17조 | 제3자 제공 별도 동의 (제공받는 자/항목/목적/기간/거부 권리 고지) |
| 개인정보보호법 제22조 | 필수/선택 분리, 동의 거부 시 서비스 거부 금지 |
| 개인정보보호법 제24조 | 민감정보(CI/DI) 별도 명시적 동의 |
| 정보통신망법 제27조의2 | 개인정보처리방침 공개 |
| Apple/Google 앱스토어 | 데이터 수집 투명성 |

### 동의 이력 보관

| 항목 | 요건 |
|------|------|
| 최소 보관 기간 | 동의 기록 2년 (개인정보보호법 시행령) |
| 권장 보관 기간 | 5년 (업계 관행, Hinge 등 글로벌 데이팅 앱 기준) |
| 보관 내용 | 동의 일시, consent_key, policy_version, 동의/철회 여부 |
| 탈퇴 시 | user_consents 별도 보관 테이블로 이동 (추후) |

## References

- **토스**: 카드형 단계적 동의 + 간결한 요약문
- **카카오**: 필수/선택 명확 구분 + 바텀시트 전문
- **당근마켓**: 전체동의 토글 + 개별 체크박스 + 선택 항목 안내문
- **Hinge**: 동의 이력 5년 보존 관행
