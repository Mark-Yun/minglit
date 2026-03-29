# Partner Terms & Privacy — 테스트 보강 계획

## 개요

`landing_partner`에 `/terms` (이용약관)과 `/privacy` (개인정보처리방침) 정적 서버 컴포넌트 페이지를 추가하는 피처의 테스트 계획.

**특성**: Next.js 서버 컴포넌트, JS 번들 0, 외부 API 호출 없음, DB 접근 없음.

---

## 계층별 테스트 계획

### Layer 1: 빌드 및 린트 검증 (CI 자동)

현재 CI(`lint-landing-partner` job)가 `npm lint + npm run build`를 실행한다. 이 피처의 1차 방어선.

| 검증 항목 | 방법 | 우선순위 |
|-----------|------|----------|
| TypeScript 컴파일 오류 없음 | `npm run build` | P1 |
| ESLint 룰 위반 없음 | `npm run lint` | P1 |
| 서버 컴포넌트에 `'use client'` 미사용 | 빌드 시 자동 검증 | P1 |

> 별도 테스트 코드 불필요 — CI에서 자동 실행됨.

### Layer 2: 콘텐츠 구조 검증 (신규 테스트)

landing_partner에 테스트 프레임워크가 없으므로, **Vitest + React Testing Library** 도입을 권장한다.
도입 비용이 낮고 (devDependency 2개), 서버 컴포넌트 렌더링 검증에 적합하다.

#### `/terms` 페이지 (`terms/page.tsx`)

| 테스트 케이스 | 검증 내용 | 우선순위 |
|---------------|-----------|----------|
| 4대 섹션 렌더링 | "서비스 이용약관", "수수료 및 정산", "계약 해지 및 탈퇴", Footer 텍스트 존재 | P1 |
| 조항 번호 순서 | 각 섹션 내 제1조~제N조 순차 렌더링 | P2 |
| Footer 회사 정보 | 상호(밍글릿), 대표자(윤민혁), 사업자등록번호(747-53-00880) 텍스트 존재 | P1 |
| 중개자 면책 조항 | landing_user와 동일 문구 확인 (제2조) | P2 |
| 페이지 metadata | `<title>`에 이용약관 관련 텍스트 포함 | P2 |

#### `/privacy` 페이지 (`privacy/page.tsx`)

| 테스트 케이스 | 검증 내용 | 우선순위 |
|---------------|-----------|----------|
| 10개 섹션 렌더링 | 수집항목~보호책임자 10개 섹션 제목 텍스트 존재 | P1 |
| 수집 항목 테이블 | 파트너 전용 항목(사업자등록번호, 정산 계좌) 포함 | P1 |
| 국외이전 섹션 | "Supabase Inc.", "미국 캘리포니아주" 텍스트 존재 | P1 |
| 위탁 업체 테이블 | 포트원, KG이니시스, 다날, Supabase, Vercel 등 수탁자 목록 | P2 |
| 보유기간 테이블 | 법정 보관 기간(전자상거래법 5년, 통신비밀보호법 3개월 등) | P2 |
| 보호책임자 정보 | 윤민혁, contact@minglit.com | P1 |
| Footer 공고일/시행일 | 날짜 텍스트 존재 | P3 |
| 페이지 metadata | `<title>`에 개인정보처리방침 관련 텍스트 포함 | P2 |

### Layer 3: 스타일 및 접근성 검증 (수동 + 자동화 가능)

| 테스트 케이스 | 검증 내용 | 우선순위 |
|---------------|-----------|----------|
| UX S1 반영: warning 토큰 | transfer-warning 영역이 `amber` 계열 시맨틱 클래스 사용 (하드코딩 `#` 컬러 미사용) | P1 |
| UX S2 반영: footer 대비 | footer 텍스트가 `text-gray-500` (`#6B7280`) 이상 대비 사용 | P1 |
| UX S3 반영: 표준 간격 | `mb-5`, `gap-10` 등 비표준 간격 미사용 (Tailwind 4px 배수만) | P2 |
| WCAG AA 색상 대비 | 모든 텍스트가 배경 대비 4.5:1 이상 | P1 |
| 모바일 반응형 | 320px~768px 뷰포트에서 가로 스크롤 없음, 텍스트 읽기 가능 | P2 |
| Pretendard 폰트 적용 | body에 Pretendard 폰트 로드 확인 | P2 |
| 파트너 브랜드 컬러 | 구분선/액센트에 `#6C3CE1` 계열 적용 | P3 |

> WCAG AA 대비 검증은 axe-core 또는 Lighthouse CI로 자동화 가능.

### Layer 4: landing_user 일관성 교차 검증

| 테스트 케이스 | 검증 내용 | 우선순위 |
|---------------|-----------|----------|
| 레이아웃 패턴 일치 | `max-w-3xl mx-auto px-6 py-12` 컨테이너 패턴 동일 | P2 |
| 중개자 면책 조항 동기화 | terms 제2조 문구가 landing_user terms와 일치 | P1 |
| Footer 구조 일관성 | 회사 정보 배치/스타일이 landing_user와 동일 패턴 | P3 |

---

## 테스트 인프라 권장사항

### 최소 구성 (P1)

landing_partner에 Vitest를 추가하여 서버 컴포넌트 렌더링 테스트를 실행:

```bash
# package.json에 추가
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

```json
// package.json scripts
"test": "vitest run",
"test:watch": "vitest"
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
  },
});
```

### 테스트 파일 위치

```
apps/landing_partner/
├── test/
│   ├── setup.ts
│   ├── terms.test.tsx       ← /terms 페이지 테스트
│   └── privacy.test.tsx     ← /privacy 페이지 테스트
```

### 향후 확장 (P3)

- Playwright E2E: 실제 브라우저 렌더링 + 스크린샷 비교
- Lighthouse CI: 접근성 + 성능 자동 검증
- landing_user에도 동일 테스트 인프라 적용

---

## 실행 순서

| 우선순위 | 건수 | 내용 |
|----------|------|------|
| P1 (필수) | 12건 | 섹션 렌더링, 핵심 콘텐츠, 접근성 대비, UX 피드백 반영, 면책 조항 동기화 |
| P2 (권장) | 10건 | metadata, 조항 순서, 위탁/보유기간 테이블, 반응형, 폰트, 레이아웃 일관성 |
| P3 (선택) | 3건 | Footer 날짜, 브랜드 컬러, Footer 일관성 |
| **총** | **25건** | |

---

## 비고

- 현재 landing_partner에 테스트 프레임워크가 없으므로, 이슈 #1(글로벌 스타일 정비) 또는 #3(terms 구현) 시점에 Vitest 도입을 함께 진행하는 것을 권장한다.
- 테스트 프레임워크 도입 전까지는 CI의 `npm lint + build`가 유일한 자동 검증이며, Layer 3~4는 PR 리뷰 시 수동 검증으로 대체한다.
- 서버 컴포넌트 특성상 클라이언트 상태/이벤트 테스트는 불필요하다.
