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
9. [ ] 메인 랜딩 페이지 개발 (Flutter Web)
10. [ ] 파티 예약 및 로테이션 미팅 로직 구현
11. [ ] PASS/SMS 본인인증 연동

---

## 💡 Tech Insights (Today's Progress)

### 1. Modern State Management with Riverpod
- **Goodbye Boilerplate**: 복잡한 BLoC 클래스들을 직관적인 `AsyncNotifier`와 `Provider`로 대체했습니다.
- **Compile-safe DI**: `GetIt`의 런타임 위험성을 제거하고, 컴파일 타임에 의존성을 검증하는 구조를 갖췄습니다.

### 2. Router-agnostic UI (Coordinator Pattern)
- **Decoupling**: UI 위젯은 다음 페이지가 무엇인지 알 필요가 없습니다. 모든 네비게이션 로직은 `Coordinator` 클래스에 캡슐화되어 유지보수성이 극대화되었습니다.
- **Type-safe Routing**: `go_router_builder`를 통해 URL 문자열 하드코딩을 방지하고 컴파일러의 도움을 받습니다.

### 3. Craftsmanship: Zero Warning Policy
- `very_good_analysis` 룰을 기반으로 프로젝트 전체의 모든 린트 경고를 해결했습니다. (Line length, discarded futures, catch clauses 등)
- 고품질의 `ARCHITECTURE.md`와 각 앱별 `README.md`를 작성하여 문서화 수준을 끌어올렸습니다.