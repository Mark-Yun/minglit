# 🏗️ Minglit Architecture Guide

> **"Simplicity is the ultimate sophistication."**  
> Minglit 프로젝트는 **간결함**, **타입 안전성**, **확장성**을 최우선으로 설계되었습니다.

---

## 1. 🛠️ Core Tech Stack

| Category | Technology | Reason |
| --- | --- | --- |
| **Framework** | Flutter (3.x) | Cross-platform development |
| **Language** | Dart | Type-safe, Null-safe |
| **State Management** | **Riverpod** | Compile-safe Dependency Injection & State Management |
| **Routing** | **GoRouter** (Type-safe) | Deep linking, Web support, Typed Routes |
| **Backend** | **Supabase** | Auth, DB(Postgres), Storage, Real-time |
| **Architecture** | Feature-first + Coordinator | Decoupled UI & Navigation |

---

## 2. 🧩 Key Architectural Patterns

### 2.1 Feature-first Structure
모든 코드는 **"기능(Feature)"** 단위로 응집되어 있습니다. `screens`나 `widgets` 같은 기술적 폴더 대신, `auth`, `member`, `verification` 같은 도메인 폴더를 사용합니다.

```text
lib/src/features/
├── auth/           # 로그인, 회원가입
├── member/         # 멤버 관리 (리스트, 권한 수정)
└── verification/   # 인증 심사 (리스트, 상세)
```

### 2.2 Coordinator Pattern (Navigation)
**UI는 "어디로 갈지" 모릅니다.** 단순히 Coordinator에게 "이 버튼이 눌렸다"고 알릴 뿐입니다.

*   **UI Widget**: `ref.read(memberCoordinatorProvider).goToDetail(id);`
*   **Coordinator**: `MemberPermissionRoute(id: id).push(context);`
*   **Benefits**: UI와 라우팅 로직의 완벽한 분리, 재사용성 증가.

### 2.3 Type-safe Routing
URL 문자열(`'/login'`)을 직접 입력하지 않습니다. `go_router_builder`를 사용하여 컴파일 타임에 경로와 파라미터를 검증합니다.

*   **Route Class**: `LoginRoute`, `HomeRoute`
*   **Usage**: `LoginRoute().go(context);`

### 2.4 Repository Pattern (Data Access)
Supabase SDK를 직접 UI에서 호출하지 않습니다. `Repository` 클래스가 데이터 접근을 추상화합니다.

*   **Repository**: `PartnerRepository`, `AuthRepository`
*   **Usage**: `ref.read(partnerRepositoryProvider).getMembers(id);`

---

## 3. 🌊 Data Flow

1.  **Repository**: Supabase에서 데이터를 가져옵니다. (`Future<List<Member>>`)
2.  **Provider**: Repository 데이터를 관리하고 캐싱합니다. (`@riverpod Future<List> memberList(...)`)
3.  **UI**: Provider를 구독(`ref.watch`)하여 화면을 그립니다. 로딩/에러 상태는 `AsyncValue`가 처리합니다.
4.  **Coordinator**: 사용자의 액션(버튼 클릭)을 받아 라우팅이나 상태 변경을 수행합니다.

---

## 4. 📁 Project Structure (Monorepo)

```text
minglit/
├── apps/
│   ├── app_partner/     # 사장님용 앱 (Web/Tablet)
│   └── app_user/        # 일반 유저용 앱 (Mobile)
└── shared/
    └── packages/
        └── minglit_kit/ # 공용 UI, Data Models, Repositories
```

*   **minglit_kit**: 모든 앱에서 공통으로 사용하는 핵심 로직과 UI 컴포넌트가 모여 있습니다. 비즈니스 로직의 중복을 막는 핵심 패키지입니다.
