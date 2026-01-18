# 범용 소셜 그래프 시스템 명세서 (Spec)

## 목표
`Party`, `Partner`, `Review` 등 다양한 대상에 대해 좋아요(Like), 구독(Subscribe), 북마크(Bookmark) 등의 소셜 인터랙션을 통합 관리하는 시스템을 구축합니다. 로그성 데이터(`user_actions`)와 상태성 데이터(`social_interactions`)를 분리하여 성능과 유지보수성을 확보합니다.

## 데이터베이스 설계

### Enums
```sql
create type public.social_target_type as enum ('party', 'partner', 'review', 'comment');
create type public.social_interaction_type as enum ('like', 'subscribe', 'bookmark', 'block');
```

### Table: `social_interactions`
| Column | Type | Constraint | Description |
|---|---|---|---|
| `user_id` | uuid | PK, FK(auth.users) | 행위 주체 |
| `target_id` | uuid | PK | 대상 ID (다형성) |
| `target_type` | enum | | 대상 타입 |
| `interaction_type` | enum | PK | 인터랙션 종류 |
| `created_at` | timestamptz | | 생성 일시 |

*   **PK:** `(user_id, target_id, interaction_type)` 복합키를 사용하여 중복 방지 및 토글 기능 지원.

## 클라이언트 아키텍처

### 1. Domain Layer
- `SocialInteraction` 모델 정의.
- `InteractionKey` (targetId, targetType, interactionType) 정의.

### 2. Data Layer (`SocialRepository`)
- `toggleInteraction(key)`: Insert/Delete 수행.
- `getInteractionState(key)`: 현재 상태 조회.
- `getInteractionCount(targetId, targetType, interactionType)`: 총 개수 조회.

### 3. Presentation Layer
- **`SocialInteractionController` (Riverpod)**
    - Optimistic UI 적용: 사용자 액션 즉시 반영 -> 서버 요청 -> 실패 시 롤백.
- **`MinglitSocialButton` (Widget)**
    - 재사용 가능한 버튼 컴포넌트.
    - 애니메이션 효과 (하트 뿅뿅 등) 지원.

## 통합 계획
- 기존 `01_core.sql`, `02_users.sql` 마이그레이션 파일들과 충돌하지 않도록 새로운 마이그레이션 파일(`07_social_graph.sql`) 생성.
- `minglit_kit`에 로직 및 UI 구현.
