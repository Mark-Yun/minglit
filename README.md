# Minglit

소셜 이벤트 매칭 플랫폼. Flutter 앱(유저/파트너) + Next.js 랜딩 + Supabase 백엔드 모노레포.

## Project Structure

```
apps/
  app_user/              # Flutter 유저 앱
  app_partner/           # Flutter 파트너 앱
  landing_user/          # Next.js 유저 랜딩
  landing_partner/       # Next.js 파트너 랜딩
  integration_scenario_tester/

shared/packages/
  minglit_kit/           # 공유 UI/로직 패키지
  minglit_lints/         # 커스텀 린트 룰
  minglit_iamport_v1/    # 결제 연동
  minglit_identification_v2/  # 본인인증

supabase/
  functions/             # Edge Functions (Deno/TypeScript)
  migrations/            # DB 마이그레이션
  config.toml

minglit_env/             # 환경변수 (private submodule)
scripts/                 # 유틸리티 스크립트
```

## Prerequisites

- Flutter SDK (stable)
- Node.js 18+
- Deno 1.40+
- Supabase CLI
- Docker Desktop (로컬 Supabase용)

## Setup

### 1. Clone

```bash
git clone https://github.com/Mark-Yun/minglit.git
cd minglit
git submodule update --init
```

### 2. Environment Variables

환경변수는 `minglit_env/` private submodule로 관리. 접근 권한 필요.

```
minglit_env/
  local/     # 로컬 개발 (supabase start)
  dev/       # 데브 서버
```

각 디렉토리에 `flutter.env`, `nextjs.env`, `supabase.env` 파일이 있음. `FILL_THIS`를 실제 값으로 교체.

### 3. Local Supabase

```bash
supabase start
```

### 4. Seed Test Data

```bash
curl -s -X POST http://127.0.0.1:54321/functions/v1/dev-seed-database
```

## Running

### Flutter

```bash
# VS Code: F5 → "app_user (local env)" 또는 "app_partner (local env)" 선택

# CLI
cd apps/app_user
flutter run -t lib/dev_main.dart --dart-define-from-file=../../minglit_env/local/flutter.env
```

### Next.js

```bash
npm run dev:user:local      # 유저 랜딩 (로컬 Supabase)
npm run dev:user:dev        # 유저 랜딩 (데브 서버)
npm run dev:partner:local   # 파트너 랜딩 (로컬)
npm run dev:partner:dev     # 파트너 랜딩 (데브)
```

### Environment Loader (Shell)

```bash
source scripts/load-env.sh local   # 로컬 환경변수 export
source scripts/load-env.sh dev     # 데브 환경변수 export
```

## Testing

```bash
# Flutter
cd shared/packages/minglit_kit && flutter test
cd apps/app_user && flutter test
cd apps/app_partner && flutter test

# Edge Functions (Deno)
cd supabase/functions/dev-session-switch && deno test --allow-env --allow-net
cd supabase/functions/dev-seed-database && deno test --allow-env --allow-net

# Lint
flutter analyze
```

## Edge Functions

| Function | Purpose |
|----------|---------|
| `dev-session-switch` | 테스트 유저 목록 조회 (dev only) |
| `dev-seed-database` | 테스트 데이터 시딩 (dev only) |
| `notification-worker` | FCM 푸시 알림 |
| `update-user-profile` | 유저 프로필 임베딩 |
| `vector-worker` | 파티 벡터화 |
| `verify-payment-v1` | 결제 검증 |
| `verify-identity-v1/v2` | 본인인증 |
| `portone-webhook-v1` | 결제 웹훅 |
| `cancel-payment` | 결제 취소 |
| `report-bug` | 버그 리포트 |

dev-only 함수들은 프로덕션에서 403 반환 (`DENO_DEPLOYMENT_ID` guard clause).

## Search (PGroonga)

한글 전문 검색을 위해 [PGroonga](https://pgroonga.github.io/) extension 사용.

### RPC Functions

```sql
-- 이벤트 제목 검색 (최대 20건)
SELECT * FROM search_events_pgroonga('직장인');

-- 파티 제목 검색 (최대 20건)
SELECT * FROM search_parties_pgroonga('대학생');
```

### Dart (Supabase Client)

```dart
final events = await supabase.rpc('search_events_pgroonga', params: {'query': '강남'});
final parties = await supabase.rpc('search_parties_pgroonga', params: {'query': '금요'});
```

### PGroonga Operators

| Operator | 용도 | 예시 |
|----------|------|------|
| `&@~` | 전문 검색 (AND/OR) | `'직장인 강남'` (AND), `'직장인 OR 대학생'` (OR) |
| `&@` | 단순 매칭 | `'직장인'` |
| `&@*` | 정규식 검색 | `'직장.*밍글'` |
