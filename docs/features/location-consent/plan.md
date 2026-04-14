# 위치정보 이용약관 및 동의 UI — 기술 설계

> Issue: #1449 | Parent: #1445 (법률 검토)

## 아키텍처 결정

### OS 권한만으로 위치정보법 동의 요건이 충족되는가?

**결론: 아니오.** 별도 앱 내 동의가 필요하다.

**근거:**
- 위치정보법 제18조: 위치기반서비스사업자가 개인위치정보를 이용하려면 **이용약관 내용**, **수집 사실·목적·범위**, **보유기간**에 대해 동의를 받아야 함
- OS 권한 다이얼로그는 "이 앱이 위치에 접근합니다" 수준이며, 법정 고지 항목(이용약관 내용, 보유기간 등)을 포함하지 않음
- 따라서 앱 내에서 위치정보 이용약관 동의 UI를 별도로 제공해야 함

### 동의 시점: 회원가입 시 선택 동의

- `locationConsent`는 **선택 동의**로 회원가입 동의 화면에 포함
- 위치 기능을 사용하지 않는 유저에게도 사전에 동의 기회를 제공 (progressive consent 대신 signup consent에 통합)
- 미동의 시 위치 기반 기능(가까운 거리 필터 등) 사용 시 개별 안내 가능 (후속 이슈)

## 변경 범위

### 1. ConsentType enum 확장 (minglit_kit)

**파일**: `shared/packages/minglit_kit/lib/src/data/models/user_consent.dart`

```dart
/// 위치정보 이용 동의 (선택)
@JsonValue('location_consent')
locationConsent,
```

- `requiredTypes`에는 추가하지 않음 (선택 동의)
- freezed codegen 재실행 필요

### 2. 회원가입 동의 화면 (app_user)

**파일**: `apps/app_user/lib/src/features/consent/ui/signup_consent_page.dart`

`_consentDefinitions` map에 `locationConsent` 항목 추가:
- 위치: `identityVerification` 앞 (선택 동의 그룹)
- 제목: "위치정보 이용 동의"
- 요약: "가까운 이벤트 추천을 위해 위치정보를 수집해요."
- detail: 위치정보법 제18조 고지 항목 포함 (수집 방법, 이용 범위, 보유기간, 동의 거부 안내)

### 3. 개인정보 설정 화면 (app_user)

**파일**: `apps/app_user/lib/src/features/settings/privacy_page.dart`

동의 현황 섹션에 위치정보 동의 SwitchListTile 추가:
- 위치: 마케팅 동의 아래, 본인인증 위
- 제3자 제공, 마케팅과 동일한 토글 패턴

약관 보기 섹션에 위치정보 이용약관 ListTile 추가.

### 4. 위치정보 이용약관 랜딩 페이지 (landing_user)

**파일**: `apps/landing_user/src/app/location-terms/page.tsx` (신규)

위치정보법 제21조 필수 포함 사항:
1. 위치기반서비스의 내용 및 요금
2. 개인위치정보의 수집 방법 및 이용 범위
3. 이용약관 변경 절차
4. 서비스 제한 및 중지 사유
5. 개인위치정보주체의 권리
6. 손해배상에 관한 사항

기존 terms/page.tsx, privacy/page.tsx와 동일한 디자인 패턴 사용.

### 5. DB 마이그레이션 (supabase)

**파일**: `supabase/migrations/20260415000001_location_consent_policy.sql` (신규)

- `policies` 테이블에 `location_consent` 정책 문서 v1 삽입
- `consent_key` 컬럼 코멘트 업데이트 (location_consent 추가)
- `has_required_consents()` 변경 **불필요** (선택 동의이므로)

### 6. 테스트

- `signup_consent_page_test.dart`: locationConsent 항목 렌더링 + 토글 테스트
- `privacy_page_test.dart`: 위치정보 동의 토글 테스트
- `consent_repository_test.dart`: 기존 테스트에 영향 없음 확인
- `consent_controller_test.dart`: 기존 테스트에 영향 없음 확인

## 태스크 분배

| 태스크 | 담당 | 파일 |
|--------|------|------|
| T1: ConsentType enum + freezed codegen + signup consent 정의 + 테스트 | dev-1 | minglit_kit, app_user |
| T2: 개인정보 설정 화면 + 약관 보기 + 테스트 | dev-1 | app_user |
| T3: 위치정보 이용약관 랜딩 페이지 | dev-2 | landing_user |
| T4: DB 마이그레이션 | dev-3 | supabase |
| T5: 코드 리뷰 | reviewer | 전체 |

## 의존성

- T1 완료 후 T2 시작 (ConsentType enum 필요)
- T3, T4는 독립적으로 병렬 진행 가능
- T5는 T1~T4 완료 후
