# 똑똑한 공개 멤버 문서화 규칙 명세서 (Spec)

## 목표
코드의 가독성과 유지보수성을 높이기 위해 공개 멤버(Public Members)에 대한 문서화 주석(`///`)을 강제하되, 불필요한 노이즈(오버라이드, 생명주기 메소드 등)는 제외하는 '똑똑한' 린트 규칙을 구현합니다.

## 규칙 상세: `minglit_require_public_docs`

### 1. 검사 대상 (Target)
- 공개(Public) 클래스, 믹스인, 익스텐션, 열거형(Enum)
- 공개 최상위(Top-level) 변수 및 함수
- 공개 필드 및 메소드

### 2. 제외 대상 (Exclusions - Smart Logic)
다음의 경우에는 문서화가 없어도 경고를 발생시키지 않습니다:
- **Private 멤버:** 이름이 `_`로 시작하는 경우.
- **Overridden 멤버:** `@override` 어노테이션이 있는 경우 (부모 클래스에 문서가 있을 것으로 가정).
- **Flutter 생명주기 메소드:** `build`, `createState`, `initState`, `dispose`, `didUpdateWidget`, `didChangeDependencies`, `deactivate`, `reassemble`.
- **Generated 코드:** `*.g.dart`, `*.freezed.dart` (Analyzer 설정으로 처리).

### 3. 메시지
- **Severity:** Info (또는 Warning, 설정 가능)
- **Message:** "Public members must be documented. Add a `///` comment."
- **Correction:** "Add documentation comments to explain the purpose of this member."

## 구현 위치
- `shared/packages/minglit_lints/lib/src/require_public_docs_rule.dart`

## 기대 효과
- 핵심 비즈니스 로직(Repository, Controller)과 커스텀 위젯의 인터페이스에 대한 설명이 풍부해짐.
- `build` 메소드마다 무의미한 주석을 달아야 하는 피로감 제거.
