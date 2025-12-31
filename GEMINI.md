# 🚀 Project Minglit (밍글릿)
> **Verified Vibe, Spark Your Moment**

신뢰와 설렘이 공존하는 검증 기반 블라인드 미팅 서비스입니다.

---

## 💎 Brand Identity
- **Name:** Minglit (Mingle + Lit) - 즐겁게 어우러지는 파티, 설렘의 불꽃이 켜지는 순간.
- **Slogan:** Verified Vibe, Spark Your Moment
- **Core Values:** 신뢰, 안전, 보장, 설렘, 귀여움
- **Primary Colors:**
  - `Midnight Navy`: 신뢰와 안전 (#1A237E)
  - `Spark Orange`: 설렘과 활기 (#FF7043)
  - `Champagne Gold`: 고급스러운 사교 (#F5E6CA)

---

## 🏗️ Architecture: Unified Repo (Monorepo)
1인 개발 최적화를 위한 단일 저장소 구조입니다.

```text
minglit/ (Root)
├── apps/
│   ├── app_partner/     # Flutter 기반 partner 용 Web 서비스
│   └── app_user/        # Flutter 기반 user용 Web/App 서비스
├── backend/
│   └── supabase/        # SQL Migration 및 Backend 로직 (PostgreSQL)
└── shared/
    ├── assets/          # 로고, 이미지, 폰트 공용 자산
    ├── docs/            # 기획서 및 API 명세
    └── packages/        # 공용 Dart/Flutter 패키지
        └── minglit_kit/ # 공용 UI 및 서비스 (Auth, Repositories)
```

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Web-First, 이후 iOS/Android 확장)
* **Backend:** Supabase (Auth, Database, Storage, Real-time)
* **Database Management:** SQL Migration (Supabase CLI 기반 형상 관리)
* **CI/CD:** GitHub Actions + Vercel
* **State Management:** **Riverpod** (AsyncNotifier, Generator)
* **Navigation:** **GoRouter** (Type-safe, Coordinator Pattern)

---

## 📝 DB Schema (Initial)
Organization-Member 모델을 기반으로 설계되었습니다.
- `user_profiles`: 모든 사용자의 기본 프로필.
- `partners`: 매장/법인 정보.
- `partner_member_permissions`: 매장 소속 직원 및 세분화된 기능 권한 관리.

---

## 📅 Roadmap

1. [x] 프로젝트 네이밍 및 브랜딩 확정
2. [x] Unified Repo 폴더 구조 세팅
3. [x] Supabase CLI 연동 및 로컬 개발 환경 구축 (`minglit-local`)
4. [x] Flutter 프로젝트 초기화 (`app_user`, `app_partner`)
5. [x] CI/CD 환경 구축 (GitHub Actions + Vercel)
6. [x] Supabase 환경별 연동 (Dev/Main) 및 자동 배포 파이프라인
7. [x] 공용 UI 패키지(`minglit_kit`) 구축 및 Google 로그인 연동
8. [x] **아키텍처 대전환: Bloc/GetIt -> Riverpod/GoRouter/Coordinator**
    - 전역 의존성 주입(DI)을 Riverpod Provider로 일원화
    - 타입 안전한 라우팅 및 네비게이션 로직 분리(Coordinator)
    - 전체 프로젝트 **Zero Warning** 달성
9. [x] **통합 개발 환경 구축 및 데이터 무결성 강화**
    - `auth.users` 가입 시 `user_profiles` 자동 생성 SQL 트리거 구축
    - `minglit_kit` 기반 공용 `DatabaseSeeder` (Admin API) 구현
    - 개발자용 `Session Switcher` 및 스마트 시딩 UI 구축 (User/Partner 앱 공통)
10. [ ] 메인 랜딩 페이지 개발 (Flutter Web)
11. [x] 카카오맵 연동 및 장소 검색 기능 구현
    - Kakao Local REST API 기반 장소 검색 (`KakaoLocationRepository`)
    - Flutter Web용 커스텀 카카오맵 위젯 (`HtmlElementView` + JS Interop)
    - 주소 복사 및 외부 지도 연결 편의 기능
12. [ ] 파티 예약 및 로테이션 미팅 로직 구현
13. [ ] PASS/SMS 본인인증 연동

---



## 🏗️ Architectural Highlights



### 1. Robust Data Integrity (Backend)

- **Atomic Profile Sync**: DB 트리거(`handle_new_user`)를 통해 `auth.users`와 `user_profiles` 간의 원자적 동기화를 보장합니다.

- **Strict Consistency Policy**: 프로필 생성 실패 시 가입 자체를 차단하여 시스템 내 "좀비 계정" 발생을 원천 봉쇄하는 무결성 정책을 준수합니다.



### 2. High-Efficiency DX (Developer Experience)

- **Programmatic Database Seeder**: 불안정한 SQL 기반 시딩을 지양하고, Supabase Admin API를 사용하는 Dart 기반 시더를 구축하여 비밀번호 해시 호환성 및 복잡한 관계 설정을 100% 코드로 제어합니다.

- **Smart Session Switcher**: 개발자 도구에서 실시간 데이터 유무를 감지하여 시딩을 제안하고, 원클릭으로 100여 명의 테스트 유저 세션을 광속으로 전환할 수 있는 지능형 UI를 제공합니다.



### 3. Sustainable Shared Kit Architecture



- **Zero Redundancy**: 모든 핵심 비즈니스 로직, 모델, 리포지토리, 그리고 개발 도구까지 `minglit_kit` 공용 패키지에 캡슐화하여 `app_user`와 `app_partner` 간의 코드 중복을 0%로 유지합니다.



- **Type-safe Dependency Injection**: Riverpod Provider를 전역 DI 시스템으로 활용하여, 런타임 오류 없이 컴파일 타임에 모든 의존성을 검증합니다.



- **Safe State Management**: AsyncNotifier와 Generator를 사용하여 비동기 상태를 선언적으로 관리하며, 특히 비동기 업데이트 중 발생할 수 있는 메모리 해제 오류(`disposed ref`)를 철저히 방지하는 안전 패턴을 적용했습니다.







### 4. Modern Navigation & Logic Decoupling



- **Coordinator Pattern**: UI 위젯은 내비게이션의 "목적지"를 알 필요가 없습니다. 모든 라우팅 로직은 전용 `Coordinator` 클래스에 캡슐화되어 UI와 비즈니스 흐름의 완벽한 분리를 달성했습니다.



- **Type-safe Routing (GoRouter)**: `go_router_builder`를 통해 URL 문자열 하드코딩을 완전히 제거했습니다. 모든 경로는 컴파일 타임에 정적으로 검증되어 오타로 인한 라우팅 오류를 원천 차단합니다.



- **Dynamic Auth Redirects**: 유저의 인증 상태(Riverpod Auth Provider)를 실시간으로 감지하여 보호된 경로(Protected Routes)에 대한 접근을 선언적으로 제어합니다.







### 5. Craftsmanship & Quality

- **Zero Warning Policy**: `very_good_analysis` 룰을 기반으로 프로젝트 전체의 린트 경고를 0으로 유지하는 엄격한 코드 퀄리티를 유지합니다.

- **Documentation First**: `ARCHITECTURE.md`, `AGENT.md` 등을 통해 설계 의도와 업무 수칙을 명문화하여 프로젝트의 지속 가능성을 확보했습니다.
