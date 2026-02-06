# 🚀 Project Minglit (밍글릿)
> **Verified Vibe, Spark Your Moment**

신뢰와 설렘이 공존하는 검증 기반 블라인드 미팅 서비스입니다.

---

## 💎 Brand Identity
- **Name:** Minglit (Mingle + Lit)
- **Slogan:** Verified Vibe, Spark Your Moment
- **Core Values:** 신뢰, 안전, 보장, 설렘, 귀여움
- **Primary Colors (from MinglitTheme):**
  - `Primary (Purple)`: #9900FF (메인 브랜드 색상)
  - `Secondary (Orange)`: #FF9900 (포인트 및 활기)
  - `Tertiary (Mint)`: #48C9B0 (보조 및 강조)
  - `Surface (Light Grey)`: #F9FAFB (배경 및 카드)

---

## 🛠️ Tech Stack
*   **Frontend:** Flutter (Web-First)
*   **Backend:** Supabase (Auth, DB, Storage, Real-time)
*   **State Management:** Riverpod (AsyncNotifier, Generator)
*   **Navigation:** GoRouter (Type-safe with Coordinator Pattern)

---

## 🗺️ Project Structure (The AI's Guide)

### 1. Apps (`/apps`)
*   **`app_partner`**: 사장님용 관리자 웹/앱. 파티 기획, 회차 관리, 티켓 발행, 유저 심사 담당.
*   **`app_user`**: 일반 유저용 앱. 파티 탐색, 티켓 구매, 본인 인증 담당.

### 2. Shared Kit (`/shared/packages/minglit_kit`)
모든 비즈니스 로직과 공용 UI의 **Single Source of Truth**.
*   `lib/src/data`: API 클라이언트, 리포지토리, 데이터 모델 (Party, Event, Ticket, User).
*   `lib/src/logic`: 공용 프로바이더 및 비즈니스 로직.
*   `lib/src/ui`: 공용 위젯 및 디자인 토큰 (`MinglitTheme`, `MinglitImage` 등).
*   `lib/src/features`: 앱 간 공유되는 대형 기능 단위 (Auth, Search).

### 3. Backend (`/supabase`)
*   `migrations/`: SQL 스키마 및 데이터 무결성을 위한 트리거 로직.
*   `seed.sql`: 개발용 초기 데이터 세팅.

---

## 🎯 Key Domain Locations (Feature Map)

| Domain | `minglit_kit` (Shared) | `app_partner` (Specific) |
| --- | --- | --- |
| **Auth** | `src/features/auth` | 로그인 화면 및 가입 신청 |
| **Search** | `src/features/search` | 카카오맵 기반 장소 검색 |
| **Party** | `src/data/models/party.dart` | 파티 기획 및 수정 위저드 |
| **Event** | `src/data/models/event.dart` | 회차(인스턴스) 생성 및 관리 |
| **Ticket** | `src/data/models/ticket.dart` | 티켓 템플릿 관리 |

---

## 🏗️ Architectural Core Patterns

상세한 협업 가이드는 [COLLABORATION_PLAYBOOK.md](./COLLABORATION_PLAYBOOK.md)을 참조하세요.

1.  **Coordinator Pattern**: UI 위젯은 경로를 알지 못하며, `Coordinator` 클래스를 통해 화면 이동을 수행합니다.
2.  **Aggregation Strategy**: 이벤트 위젯은 파티 위젯을 감싸서(Wrapper) 구현하며 코드 중복을 0%로 유지합니다.
3.  **Smart Initializer**: `EventCreateController`처럼 부모 데이터를 복사하여 상태를 초기화하는 '똑똑한 컨트롤러' 방식을 지향합니다.

---

## 📅 Roadmap (High Level)

1. [x] 아키텍처 대전환 (Riverpod/GoRouter)

2. [x] 통합 개발 환경 구축 (Smart Session Switcher)

3. [x] 카카오맵 연동 및 장소 검색

4. [x] 이벤트 생성 시스템 리팩터링 (Aggregation)

5. [x] 에러 핸들링 표준화 (Layered Trust Error System)

6. [x] 신뢰 기반 입장 시스템 (Identity & Admission Flow)

7. [ ] 메인 랜딩 페이지 개발

8. [ ] PASS/SMS 본인인증 실연동 (현재 Mock 구현)



---



## 📝 Recent Context & Decisions (2026-01-12)



### 1. Error Handling Standardization

*   **Goal**: 일관된 에러 경험 제공 및 보안 강화.

*   **Solution**: `minglit_kit`의 `handleMinglitError`로 로직 중앙화.

*   **Usage**: UI에서는 `handleMinglitError(context, e)` 호출, Riverpod에서는 `ref.listen(..., (_, next) => next.showMinglitError(context))` 사용.



### 2. Trust-based Admission System

*   **Philosophy**: "확실하지 않으면 심사받아라" (Verified Vibe).

*   **Structure**:

    *   **Identity (신원)**: `users` 테이블의 필수 속성(`birth_date`, `gender`). PASS/SMS로 자동 검증 (Base Layer).

    *   **Qualification (자격)**: `verifications` 테이블. 직장, 학력 등 파트너가 심사하는 추가 속성 (Add-on Layer).

*   **Flow**:

    *   `EventAdmissionController`가 유저 상태를 판별 (`guest` -> `identityRequired` -> `notEligible` -> `eligible`).

    *   `EventDetailScreen`에서 상태에 따라 {로그인} -> {본인인증} -> {티켓선택}으로 물 흐르듯 유도.
