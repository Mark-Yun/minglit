# Minglit Engineering Standards Index (2026 Policy)

**Description**: Minglit 프로젝트의 기술별 리뷰 가이드 및 엔지니어링 정책을 통합 관리하는 인덱스입니다. 본 문서는 단순한 참조를 넘어, 에이전트와 개발자가 시스템 설계 및 코드 리뷰 시 준수해야 할 **'Minglit 기술 헌법'**으로 작동합니다.

---

## 🚀 영역별 엔지니어링 정책 (Engineering Policies)

1.  **[Core Engineering Principles](./engineering-principles.md)** 🌟
    *   **Focus**: 클린 아키텍처, 의존성 주입(DI), 상속보다 합성, YAGNI 원칙 등 범용 SE 표준.
2.  **[Flutter & Riverpod 3.0](./flutter-riverpod-3.0.md)**
    *   **Focus**: 검증된 엔티티 경계, 수평적 저장소 확장, 리액티브 캐시 수명 주기 관리.
3.  **[Supabase Platform & Infrastructure](./supabase-platform.md)**
    *   **Focus**: AAL 기반 차등 권한 제어, 제로 트러스트 세션 검증, 선응답 후처리 이벤트 아키텍처.
4.  **[PostgreSQL 18 & RLS Performance](./postgres-18-rls.md)**
    *   **Focus**: InitPlan 쿼리 최적화, 병렬 인덱스 스캔, 물리적 RLS(Partitioning) 전략.
5.  **[Deno 2.0 & Edge Functions](./deno-2.0-edge.md)**
    *   **Focus**: 전역 싱글톤 재사용, JSR 모듈 표준, 분산 추적(Trace-ID) 및 비지연 로깅.
6.  **[GitHub Actions & CI/CD](./github-actions-cicd.md)**
    *   **Focus**: OIDC 기반 정적 시크릿 제거, 밀폐형 빌드(Hermetic), 고속 배포 벨로시티 정책.

---

## 🛠️ 활용 가이드 (Usage)

*   **리뷰 에이전트**: PR의 변경 성격에 따라 **Core Principles**를 최우선으로 적용하고, 파일 경로에 맞는 기술별 표준을 병행 참조하십시오.
*   **개발 에이전트**: 설계 단계에서 위 문서의 **[Rule]**과 **[Deep-dive]**를 통해 빅테크 수준의 아키텍처를 구현하십시오.
*   **설계 에이전트 (Arch)**: 새로운 기능 모듈 추가 시, 본 인덱스의 계층화 원칙을 준수하여 시스템 경계를 정의하십시오.
