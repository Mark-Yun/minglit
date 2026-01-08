# 📦 Minglit Kit

> Minglit 프로젝트의 **공용 비즈니스 로직**과 **UI 컴포넌트**를 담고 있는 핵심 패키지입니다.
> `app_user`와 `app_partner`는 이 패키지를 import하여 사용합니다.

---

## 📂 Structure

```text
lib/
├── minglit_kit.dart        # 메인 진입점 (Export)
├── minglit_core.dart       # 핵심 유틸리티 (Logger 등)
├── minglit_data.dart       # 데이터 레이어 (Repositories, Models)
├── minglit_logic.dart      # 로직 레이어 (Providers)
├── minglit_ui.dart         # UI 레이어 (Widgets)
└── src/
    ├── data/
    │   ├── models/         # Freezed Data Models
    │   └── repositories/   # Supabase Access Repositories
    ├── logic/
    │   └── providers/      # Global Providers (Auth 등)
    └── widgets/            # Common UI Widgets (LoginScreen 등)
```

---

## 🛠️ Key Components

### Repositories (`src/data/repositories/`)
*   **`AuthRepository`**: 로그인, 로그아웃, 세션 관리.
*   **`PartnerRepository`**: 파트너 입점, 멤버 관리 DB 로직.
*   **`VerificationRepository`**: 인증 제출 및 심사 로직.

### Providers (`src/logic/providers/`)
*   **`AuthController`**: 로그인 액션의 상태(Loading/Error)를 관리하는 Riverpod Controller.

### Widgets (`src/widgets/`)
*   **`MinglitLoginScreen`**: 공용 로그인 UI.
*   **`DevScreenList`**: 개발용 화면 목록 위젯.

---

## 📝 Development Guide

1.  **Code Generation**:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
    모델이나 Provider를 수정하면 반드시 실행하세요.

2.  **Linting**:
    ```bash
    flutter analyze
    ```
    Zero Warning을 유지해주세요.