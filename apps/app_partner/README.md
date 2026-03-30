# 🏪 Minglit Partner App

> 파트너(사장님)가 매장을 관리하고, 멤버를 초대하며, 유저의 입점 신청을 심사하는 앱입니다.

---

## 📂 Folder Structure

```text
lib/
├── dev_main.dart           # 개발용 엔트리포인트 (DevMap 시작)
├── main.dart               # 프로덕션 엔트리포인트 (Router 시작)
└── src/
    ├── features/           # 기능 단위 모듈
    │   ├── admin/          # 관리자 기능 (입점 신청 관리 등)
    │   ├── auth/           # 로그인
    │   ├── home/           # 메인 대시보드
    │   ├── member/         # 직원 및 권한 관리
    │   └── verification/   # 유저 인증 심사
    └── routing/            # 라우팅 설정
        ├── app_router.dart # GoRouter 설정 (Redirect 로직 포함)
        └── app_routes.dart # Type-safe Route 정의
```

---

## 🔑 Key Features & Files

### 1. Member Management (`src/features/member/`)
*   **`PartnerMemberListPage`**: 직원 목록을 보여줍니다. `Local Provider`를 사용하여 데이터를 로딩합니다.
*   **`PartnerMemberPermissionPage`**: 직원의 권한을 수정합니다.
*   **`MemberCoordinator`**: 멤버 관련 페이지 이동 로직을 담당합니다.

### 2. Verification Review (`src/features/verification/`)
*   **`ReviewVerificationPage`**: 유저들이 제출한 인증 요청을 심사(승인/반려/보완)합니다.

### 3. Admin (`src/features/admin/`)
*   **`PartnerApplicationListPage`**: 신규 파트너 입점 신청 목록을 관리합니다.
*   **`AdminCoordinator`**: 관리자 화면 간 이동을 제어합니다.

---

## 🚀 How to Run

```bash
# 개발 모드 (DevMap으로 시작)
flutter run -t lib/dev_main.dart

# 프로덕션 모드 (로그인 화면으로 시작)
flutter run -t lib/main.dart
```