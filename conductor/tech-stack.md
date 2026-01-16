# 기술 스택

## 프론트엔드 (앱)
- **프레임워크:** Flutter (웹 우선)
- **언어:** Dart
- **상태 관리:** Riverpod (AsyncNotifier, Generator)
- **네비게이션:** GoRouter (Coordinator 패턴을 적용한 타입 안전성 확보)
- **공용 킷:** `minglit_kit` (로직 및 UI의 단일 진실 공급원 - SSOT)

## 프론트엔드 (웹 랜딩)
- **프레임워크:** Next.js (React)
- **언어:** TypeScript
- **스타일링:** Tailwind CSS / Bootstrap

## 백엔드 및 인프라
- **서비스:** Supabase (BaaS)
- **데이터베이스:** PostgreSQL (관계형)
- **인증:** Supabase Auth (OTP, 본인 확인 기관)
- **스토리지:** Supabase Storage (유저 에셋, 검증 서류)
- **배포:** Vercel (Next.js 및 Flutter 웹), GitHub Actions (CI/CD)
- **AI 및 벡터 검색:**
  - **임베딩:** OpenAI Text Embedding 3 Small
  - **벡터 DB:** pgvector (Supabase)
  - **큐:** PGMQ (Postgres Message Queue) - 비동기 처리용
  - **스케줄러:** pg_cron - 주기적 워커 실행용

## 외부 연동
- **지도:** Kakao Maps SDK (장소 검색)
- **본인인증:** PASS/SMS (신원 확인)