```markdown
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
│   └── app_partner/     # Flutter 기반 partner 용 Web 서비스
│   └── app_user/        # Flutter 기반 user용 Web/App 서비스
├── backend/
│   └── supabase/        # SQL Migration 및 Backend 로직 (PostgreSQL)
└── shared/
    ├── assets/          # 로고, 이미지, 폰트 공용 자산
    └── docs/            # 기획서 및 API 명세
```

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Web-First, 이후 iOS/Android 확장)
* **Backend:** Supabase (Auth, Database, Storage, Real-time)
* **Database Management:** SQL Migration (Supabase CLI 기반 형상 관리)
* **State Management:** Provider (예정)

---

## 📝 Initial DB Schema Concept (profiles)

```sql
create table profiles (
  id uuid references auth.users not null primary key,
  username text unique,
  avatar_url text,
  is_verified boolean default false, -- 밍글릿의 핵심 가치
  updated_at timestamp with time zone
);

```

---

## 📅 Roadmap

1. [x] 프로젝트 네이밍 및 브랜딩 확정
2. [x] Unified Repo 폴더 구조 세팅
3. [ ] Supabase CLI 연동 및 로컬 개발 환경 구축
4. [ ] Supabase Auth 연동 (로그인/가입)
5. [ ] 메인 랜딩 페이지 개발 (Flutter Web)
6. [ ] 파티 예약 및 로테이션 미팅 로직 구현

```