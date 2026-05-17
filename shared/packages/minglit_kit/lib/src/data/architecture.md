# minglit_kit/data — Repository Pattern 상세

UI 와 Supabase SDK 사이의 추상화. UI 는 Repository 호출만 알면 되고, 테이블 구조·쿼리 디테일은 Repository 안에 캡슐화.

## 기본 사용

```dart
ref.read(partnerRepositoryProvider).getMembers(partnerId);
```

Provider 는 `@riverpod` annotation 으로 자동 생성. 각 Repository 는 동명의 `xxxRepositoryProvider` 를 가진다.

## Repository Split Pattern

Repository 가 300 줄을 넘으면 Dart 의 `part`/`mixin` 패턴으로 분할한다. 한 파일에 모든 query·command 가 모이면 가독성·리뷰가 어려워짐.

```dart
// foo_repository.dart (main)
part 'foo_query_repository.dart';
part 'foo_command_repository.dart';

class FooRepository extends _SupabaseFooContextBase
    with _FooQueryRepository, _FooCommandRepository { ... }

// foo_query_repository.dart (part)
part of 'foo_repository.dart';
mixin _FooQueryRepository on _SupabaseFooContext { ... }
```

**적용 예시:**
- `event_repository` + `event_repository_queries` + `event_repository_commands`
- `verification_repository` + `verification_query_repository` + `verification_command_repository`
- `partner_repository` + `partner_member_repository` + `partner_application_repository`
- `party_repository` + `party_event_repository` + `party_matching_repository`

## Repository 가 kit 으로 가는 조건

- 두 앱 모두 필요한 데이터
- Supabase 테이블 / RPC wrap
- 단일 도메인 (events, parties, verifications, partners, ...)

## 안티패턴

- UI 에서 `Supabase.instance.client.from('...')` 직접 호출
- Provider 가 `@riverpod` 없이 manual 작성
- 한 앱만 쓰는 Repository 를 kit 에 두기 (앱 feature 폴더로)
- 한 Repository 가 300 줄 넘는데 split 안 함

## 관련

- [BLUEDOC](./BLUEDOC.md)
- [../logic/BLUEDOC.md](../logic/BLUEDOC.md) — Provider 위치 결정 가이드
- [minglit_kit/architecture.md](../../architecture.md) — 5 계층 개요
