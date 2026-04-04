# Deno 2.0 & Edge Functions Runtime Standard (v2.0)

**Description**: 본 문서는 Deno 2.0 런타임과 Hono 프레임워크를 활용한 고성능 에지 API 설계, JSR 기반 모듈 관리, 그리고 에지 레벨의 보안 헤더 강화 정책을 정의합니다. 모든 에지 엔지니어와 에이전트는 본 정책을 구현의 절대적 기준으로 삼습니다.

**References**:
*   [Deno 2.0: The TypeScript-first ESM Runtime](https://deno.com/blog/deno-2-is-here)
*   [Hono.dev: Middleware & Performance Best Practices](https://hono.dev/docs/guides/best-practices)
*   [Cloudflare Workers: Security Headers & Web Standards](https://developers.cloudflare.com/workers/runtime-apis/headers)
*   [JSR.io: Modern JavaScript Registry Standard](https://jsr.io/docs/introduction)
*   [MDN: Streams API for Edge Performance](https://developer.mozilla.org/en-US/docs/Web/API/Streams_API)

---

## 🚀 Section 1: JSR 워크스페이스 및 종속성 정책 (Workspaces)

### [Rule 1.1] JSR-Native Shared Modules
*   **Policy**: 모든 공통 모듈 및 내부 라이브러리는 반드시 **JSR(ESM-native registry)**을 통해 배포 및 관리되어야 합니다. URL 기반 임포트나 레거시 CommonJS 패키지 사용을 지양합니다.
*   **Rationale**: JSR은 TypeScript 소스를 직접 배포하며 에지 환경에 최적화된 번들링과 타입 정의를 제공합니다. 이는 Deno 2.0의 고속 실행 및 IDE 경험을 극대화합니다.
*   **Standard**: 워크스페이스 내 패키지 간 참조는 반드시 `jsr:@scope/pkg` 형식을 따르며, 엄격한 시멘틱 버저닝(SemVer)을 준수합니다.

---

## ⚡ Section 2: Hono 기반 고성능 미들웨어 정책 (Routing)

### [Rule 2.1] Handler-Centric Composition (핸들러 중심 설계)
*   **Policy**: 기존의 무거운 'Controller' 클래스 구조를 지양하고, 경로 정의 즉시 핸들러를 작성하거나 `factory.createHandlers()`를 사용하여 미들웨어를 체이닝합니다.
*   **Rationale**: 핸들러를 직접 연결함으로써 런타임의 타입 추론(Type Inference) 성능을 높이고, 복잡한 제너릭 사용으로 인한 빌드 타임 오버헤드를 방지합니다.
*   **Standard**: `app.route()`를 사용하여 서브 애플리케이션(예: `/auth`, `/api`)을 모듈화하여 장착합니다. 내부 서비스 간 통신 시에는 `hc` (Hono Client)를 활용하여 Zero-latency 타입 검증을 수행합니다.

---

## 🔐 Section 3: 에지 보안 및 헤더 관리 정책 (Edge Security)

### [Rule 3.1] RFC 6265 기반 쿠키 보안 (Set-Cookie Integrity)
*   **Policy**: 여러 개의 쿠키를 설정할 때 반드시 `headers.append()`를 사용해야 하며, 단일 헤더에 합치는 행위(Folding)를 금지합니다.
*   **Rationale**: RFC 6265 표준에 따라 브라우저는 콤마(,)로 구분된 단일 `Set-Cookie` 헤더를 올바르게 파싱하지 못할 수 있습니다.
*   **Standard**: 쿠키 조회 시에도 `headers.get()` 대신 **`headers.getAll("Set-Cookie")`**를 사용하여 데이터 손실을 방지합니다.

### [Rule 3.2] Edge-Enforced Security Headers
*   **Policy**: 모든 응답은 에지 레벨에서 다음 보안 헤더를 강제해야 합니다.
    1. **`Content-Security-Policy` (CSP)**: XSS 방어를 위한 엄격한 출처 정책.
    2. **`Strict-Transport-Security` (HSTS)**: 모든 연결을 HTTPS로 강제.
    3. **`X-Trace-Id`**: 분산 추적을 위한 고유 요청 ID.
*   **Audit Criteria**: 응답 반환 전 보안 미들웨어가 누락되어 헤더가 누락되었는가?

---

## 🛠️ 시니어 리뷰어 체크리스트 (Summary Checklist)

1.  [ ] **Workspaces**: 내부 라이브러리 참조가 `jsr:` 형식을 따르며 SemVer가 준수되었는가?
2.  [ ] **Middleware**: 무거운 컨트롤러 인스턴스화 대신 핸들러 중심의 체이닝을 사용했는가?
3.  [ ] **Cookies**: 다중 쿠키 설정 시 `append()`와 `getAll()`을 올바르게 사용했는가?
4.  [ ] **Security Headers**: CSP 및 HSTS 헤더가 에지 응답에 포함되어 있는가?
5.  [ ] **Streaming**: 대용량 데이터 전송 시 `ReadableStream`을 적용했는가?
6.  [ ] **RPC**: 내부 API 호출 시 Hono RPC(`hc`)를 통해 타입 안전성을 확보했는가?
