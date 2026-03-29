# landing_partner 이용약관/개인정보처리방침 — 기술 설계

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 예상 규모 |
|------|------|------|--------|----------|
| 1 | landing_partner 글로벌 스타일 정비 (Pretendard + 파트너 테마 변수) | needs-dev | 없음 | S |
| 2 | `shared/web/theme/tokens.ts` border 토큰 추가 | needs-dev | 없음 | S |
| 3 | `/terms` 파트너 이용약관 페이지 구현 | needs-dev | #1, #2 | M |
| 4 | `/privacy` 파트너 개인정보처리방침 페이지 구현 | needs-dev | #1, #2 | M |

> 이슈 #1, #2는 병렬 가능. #3, #4는 #1 완료 후 병렬 가능.

## 수정 대상 파일

### 인프라 (이슈 #1)

| 파일 | 변경 내용 |
|------|----------|
| `apps/landing_partner/src/app/globals.css` | Pretendard 폰트 import, 파트너 테마 CSS 변수 정의, Tailwind `@theme` 토큰 등록, `@layer base` body 기본 스타일 |
| `apps/landing_partner/src/app/layout.tsx` | `lang="ko"`, Geist 폰트 제거 또는 유지, metadata 한국어화 (title: "밍글릿 파트너"), body className 정비 |

### 공유 토큰 (이슈 #2)

| 파일 | 변경 내용 |
|------|----------|
| `shared/web/theme/tokens.ts` | `minglitColors`에 `border: '#E5E7EB'`, `borderLight: '#F3F4F6'` 추가. `partner` 컬러 그룹 추가 (`primary: '#6C3CE1'`, `primaryLight: '#8B5CF6'`, `primarySurface: '#F5F0FF'`, `primaryBorder: '#E8E0FF'`) |

### 이용약관 페이지 (이슈 #3)

| 파일 | 변경 내용 |
|------|----------|
| `apps/landing_partner/src/app/terms/page.tsx` | **신규**. 서버 컴포넌트. 4대 섹션: 서비스 이용약관(5조), 수수료 및 정산(4조), 계약 해지 및 탈퇴(3조), Footer(회사 정보) |

### 개인정보처리방침 페이지 (이슈 #4)

| 파일 | 변경 내용 |
|------|----------|
| `apps/landing_partner/src/app/privacy/page.tsx` | **신규**. 서버 컴포넌트. 10개 섹션: 수집항목·목적, 보유기간, 제3자 제공, 위탁, 국외이전, 파기, 이용자 권리, 안전성 확보, 자동화 결정 거부권, 보호책임자 + Footer |

## 아키텍처 결정

### 1. 정적 서버 컴포넌트

두 페이지 모두 `'use client'` 불필요. Next.js App Router 서버 컴포넌트로 구현하여 JS 번들 0에 가깝게 유지.

### 2. 컴포넌트 추출 여부 → 하지 않음

landing_user의 terms/privacy 각각 98줄, 248줄. 파트너 페이지도 유사 규모 예상. 공유 컴포넌트(Section, Article, Footer 등) 추출은 시기상조:
- 두 랜딩앱은 독립 배포 단위이며, 콘텐츠가 상이
- landing_user는 Racing Sans One 헤딩, landing_partner는 Pretendard 헤딩 — 스타일 분기 필요
- 현재 규모에서 DRY보다 독립성이 더 중요

### 3. globals.css 패턴 — landing_user 패턴 차용

landing_user의 `globals.css`를 참고하되, 파트너 전용으로 조정:

```css
/* 추가할 파트너 CSS 변수 */
--color-partner: #6C3CE1;
--color-partner-light: #8B5CF6;
--color-partner-surface: #F5F0FF;
--color-partner-border: #E8E0FF;
```

- Racing Sans One / Dancing Script: 파트너 랜딩에는 불필요 → import하지 않음
- Pretendard: body 기본 폰트로 설정
- h1/h2/h3에 Racing Sans One 강제 적용하지 않음 (법적 문서에 부적합)

### 4. 레이아웃 패턴

와이어프레임 기준:
- Container: `max-w-3xl mx-auto px-6 py-12` (landing_user와 동일)
- 제목: `text-2xl font-bold text-center` + `border-b-2 border-[파트너컬러]`
- 섹션 제목: flex + `w-[3px] h-4 bg-[파트너컬러]` 데코레이터 + `text-base font-bold`
- 조항: `text-sm` 본문, `text-xs` 리스트
- 테이블: `text-xs`, thead `bg-partner-surface`, th `text-partner-primary`
- Footer: `bg-gray-50 p-8 rounded-2xl`

### 5. layout.tsx 변경 범위

현재 landing_partner의 layout.tsx는 Next.js 기본 템플릿 상태. 변경:
- `lang="en"` → `lang="ko"`
- Geist 폰트 유지 가능 (Pretendard는 CSS import로 처리, 구글 폰트가 아님)
- metadata: title → "밍글릿 파트너", description → 파트너 서비스 설명
- StatsigAnalyticsProvider 유지 (이미 설정됨)

## UX 리뷰 피드백 반영 계획

| # | 피드백 | 반영 위치 | 방법 |
|---|--------|----------|------|
| S1 | transfer-warning 하드코딩 → warning 토큰 | 이슈 #3, #4 | `bg-amber-50 border-amber-300 text-amber-800` Tailwind 시맨틱 클래스 사용 (하드코딩 금지) |
| S2 | footer 텍스트 대비 `#9CA3AF`→`#6B7280` | 이슈 #3, #4 | `text-gray-500` (= `#6B7280`) 사용. WCAG AA 4.6:1 충족 |
| S3 | 비표준 간격 article mb 20→16/24, gap 10→8/12 | 이슈 #3, #4 | Tailwind 표준 간격만 사용: `mb-4`(16px) or `mb-6`(24px), `gap-2`(8px) or `gap-3`(12px) |
| S4 | tokens.ts radius 불일치 | **PR #797에서 처리 중** | 별도 작업 불필요 |
| S5 | border 토큰 부재 | 이슈 #2 | `tokens.ts`에 border 컬러 추가 |

## 리스크 및 대응

| 리스크 | 확률 | 대응 |
|--------|------|------|
| PR #797 (radius 토큰 동기화)이 먼저 머지되지 않을 경우 | 낮음 | 이슈 #3, #4에서 radius를 Tailwind 기본값(`rounded-lg` 등)으로 구현하고, 토큰 import는 하지 않음. 현재 landing_user도 tokens.ts를 import하지 않고 Tailwind 직접 사용 중 |
| 법무 검토 전 약관 문구 확정 불가 | 중간 | 페이지 레이아웃과 구조를 먼저 구현하고, 실제 문구는 placeholder 또는 spec.md 기준으로 채움. 법무 확정 후 텍스트만 교체 |
| landing_user와 약관 내용 충돌 (spec.md 에지 케이스 #1) | 낮음 | 구현 시 landing_user terms/privacy와 상호 참조. 중복 조항(중개자 면책 등)은 동일 문구 사용 |
| globals.css 정비 시 기존 page.tsx(기본 템플릿) 스타일 깨짐 | 낮음 | 기본 템플릿 page.tsx는 조만간 교체 예정. 깨져도 무방 |

## 구현 가이드 (issue-worker 참고)

### 이슈 #1: globals.css 정비

```
1. apps/landing_partner/src/app/globals.css 전면 교체
   - Pretendard @font-face import
   - @import "tailwindcss"
   - @theme { 파트너 컬러 변수, 간격, 애니메이션 }
   - @layer base { body 스타일 }
2. apps/landing_partner/src/app/layout.tsx
   - lang="ko", metadata 한국어화
3. 검증: npm run lint && npm run build (apps/landing_partner)
```

### 이슈 #2: tokens.ts border 토큰

```
1. shared/web/theme/tokens.ts
   - minglitColors에 border, borderLight 추가
   - partner 컬러 그룹 export 추가
2. 검증: npm run lint (landing_user, landing_partner 둘 다)
```

### 이슈 #3: /terms 페이지

```
1. apps/landing_partner/src/app/terms/page.tsx 신규 생성
   - 서버 컴포넌트 (use client 없음)
   - spec.md 4대 섹션 구조 그대로 구현
   - 와이어프레임 CSS 패턴 적용 (Tailwind 유틸리티)
   - UX 피드백 S1(warning 토큰), S2(footer 대비), S3(표준 간격) 반영
2. 검증: npm run lint && npm run build
```

### 이슈 #4: /privacy 페이지

```
1. apps/landing_partner/src/app/privacy/page.tsx 신규 생성
   - 서버 컴포넌트
   - spec.md 10개 섹션 + Footer
   - 테이블 컴포넌트 (위탁, 국외이전, 보유기간)
   - UX 피드백 동일 적용
2. 검증: npm run lint && npm run build
```

## 범위 외 (후속 이슈 권고)

| 항목 | 이유 | 권고 |
|------|------|------|
| landing_user `/privacy` 국외이전 조항 추가 | spec.md에서 권고. 별도 법적 문서 | needs-pm으로 별도 이슈 |
| 공유 Legal 컴포넌트 추출 | 현재 2앱 × 2페이지 = 4페이지. 추출 시점은 3앱 이상 또는 동일 구조 5페이지+ | 당분간 불필요 |
| SEO / OG 메타태그 | 법적 문서는 SEO 우선순위 낮음 | 런칭 후 필요 시 추가 |
