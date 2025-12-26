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
        └── minglit_kit/ # 공용 UI 및 서비스 (Auth 등)
```

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Web-First, 이후 iOS/Android 확장)
* **Backend:** Supabase (Auth, Database, Storage, Real-time)
* **Database Management:** SQL Migration (Supabase CLI 기반 형상 관리)
* **CI/CD:** GitHub Actions + Vercel
* **State Management:** StreamBuilder / Provider (예정)

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
    - 웹: Supabase OAuth (Redirect) 방식 적용 (디자인 자유도 확보 및 Deprecation 해결)
    - 모바일: Google Sign-In Native SDK 연동
    - **GetIt을 활용한 Service Locator (DI) 패턴 도입**
8. [ ] 메인 랜딩 페이지 개발 (Flutter Web)
9. [ ] 파티 예약 및 로테이션 미팅 로직 구현
10. [ ] PASS/SMS 본인인증 연동

---

## 💡 Tech Insights (Today's Progress)

### 1. Hybrid Auth Strategy
- **Web:** `google_sign_in` 패키지의 웹 버전 제약을 피하기 위해 `_supabase.auth.signInWithOAuth` 방식을 채택했습니다. 이를 통해 커스텀 UI를 유지하면서도 안전한 리다이렉트 인증이 가능해졌습니다.
- **Mobile:** 사용자 경험을 위해 네이티브 팝업 방식인 `signInWithIdToken`을 유지합니다.

### 2. Dependency Injection (DI) with GetIt
- `minglit_kit` 내에 `locator.dart`를 생성하여 전역적으로 서비스를 관리합니다.
- `AuthService`를 싱글톤(LazySingleton)으로 등록하여, 어느 위젯에서든 `locator<AuthService>()`로 일관된 상태에 접근할 수 있습니다.

### 3. Local Development Environment
- `localhost:3000`과 `127.0.0.1:3000` 모두에서 인증 리다이렉트가 작동하도록 `config.toml`을 최적화했습니다.
- 보안 민감 정보(Client Secret 등)는 `backend/supabase/.env`에서 관리하도록 설정했습니다.
