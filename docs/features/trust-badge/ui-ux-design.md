# Trust Badge UI/UX Design

## 1. Design Tokens (Visual)

신뢰 배지는 유저의 신뢰도를 시각적으로 상징하므로, 일반적인 아이콘보다 더 강조되고 프리미엄한 느낌을 주어야 한다.

### 1.1 Level별 아이콘 및 색상

| 레벨 | 아이콘 (Material) | 기본 색상 | 포인트/그라디언트 |
|---|---|---|---|
| **Verified (🛡️)** | `Icons.verified_user` | `MinglitColors.primary` (Purple) | - |
| **Certified (✨)** | `Icons.auto_awesome` | `MinglitColors.secondary` (Amber) | Amber -> Orange Gradient |
| **Elite (💎)** | `Icons.diamond` | `MinglitColors.tertiary` (Mint) | Mint -> Cyan Gradient |

### 1.2 배지 스타일 (TrustBadge Widget)

- **Size**:
    - `Small`: 14x14 px (유저 리스트, 채팅 등 텍스트 옆)
    - `Medium`: 20x20 px (프로필 헤더, 카드 상단)
- **Shape**: 기본적으로 아이콘 단독 노출. 필요시 서클 배경(`surfaceVariant`) 추가.
- **Micro-interaction**: 클릭 시 햅틱 피드백 + `TrustSheet`가 아래에서 부드럽게 슬라이드업.

---

## 2. Trust Sheet (바텀 시트) 구조

`TrustSheet`는 배지의 근거를 설명하는 가장 중요한 컴포넌트이다.

### 2.1 레이아웃 설계

1.  **Header Section**
    - 유저 아바타 (48px) + 유저 이름 (`titleLarge`)
    - "현재 **[레벨명]** 등급입니다" 문구 (`labelMedium`, 색상 강조)
2.  **Trust Progress Section (3-Step)**
    - 🛡️ -> ✨ -> 💎 순서의 가로 스텝퍼(Stepper) 또는 칩 형태.
    - 달성한 단계는 컬러풀하게, 미달성 단계는 회색(`muted`)으로 표시.
3.  **Verification List Section**
    - `VerificationCard` 재사용 (readonly 모드).
    - 예: "삼성전자 (재직인증 완료)", "서울대학교 (학력인증 완료)".
4.  **Reliability Stats Section**
    - 아이콘 + 텍스트 조합.
    - "최근 10회 참여 중 10회 출석 (출석률 100%)"
    - "신고 이력 없음"
5.  **Footer**
    - "나도 인증하고 신뢰도 높이기" 버튼 (본인 시트일 경우)
    - "닫기" 버튼

---

## 3. 적용 화면 (Placement)

### 3.1 My Page (마이페이지)
- 유저 이름 우측에 `Medium` 사이즈 배지 노출.
- 배지 영역 클릭 시 본인의 `TrustSheet` 오픈.
- 미인증 시 "신뢰도를 높여보세요 >" 텍스트 링크 노출.

### 3.2 Participant List (참가자 목록)
- 유저 아바타 우측 하단 또는 이름 옆에 `Small` 사이즈 배지 노출.
- 타 유저 배지 클릭 시 해당 유저의 `TrustSheet` 오픈.

### 3.3 Chat (채팅)
- 말풍선 옆 유저 이름 뒤에 `Small` 사이즈 배지 노출.

---

## 4. 다크모드 대응
- 배지 아이콘은 `MinglitColorsDark`에 맞춰 대비가 충분하도록 조정.
- `TrustSheet` 배경은 `MinglitColorsDark.surface` 사용.
- 그라디언트 포인트 컬러의 명도를 소폭 상향하여 시인성 확보.
