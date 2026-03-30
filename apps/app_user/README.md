# 👤 Minglit User App

> 일반 사용자가 파티에 참여하고, 인증을 수행하며, 프로필을 관리하는 모바일 앱입니다.

---

## 📂 Folder Structure

```text
lib/
├── dev_main.dart           # 개발용 엔트리포인트 (DevMap 시작)
├── main.dart               # 프로덕션 엔트리포인트 (Router 시작)
└── src/
    ├── features/           # 기능 단위 모듈
    │   ├── auth/           # 로그인
    │   ├── home/           # 메인 홈
    │   └── verification/   # 인증 제출 및 관리
    └── routing/            # 라우팅 설정
        ├── app_router.dart # GoRouter 설정
        └── app_routes.dart # Type-safe Route 정의
```

---

## 🔑 Key Features & Files

### 1. Verification (`src/features/verification/`)
*   **`VerificationManagementPage`**: 유저가 자신의 인증 상태를 확인하고 서류를 제출하는 핵심 페이지입니다.
*   **`VerificationInboxPage`**: 파트너로부터 온 보완 요청 알림을 확인합니다.
*   **`VerificationCoordinator`**: 인증 관련 화면 이동을 담당합니다.

### 2. Auth (`src/features/auth/`)
*   **`LoginPage`**: Google/Kakao 소셜 로그인을 처리합니다.
*   **`AuthWrapper`**: (Legacy/Dev) 인증 상태에 따라 화면을 분기하는 위젯입니다.

---

## 🚀 How to Run

```bash
# 개발 모드 (DevMap으로 시작)
flutter run -t lib/dev_main.dart

# 프로덕션 모드
flutter run -t lib/main.dart
```