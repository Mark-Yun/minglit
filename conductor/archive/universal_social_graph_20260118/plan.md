# Implementation Plan: Universal Social Graph

- [x] **Step 1: 데이터베이스 마이그레이션**
  - `supabase/migrations/20260118000000_07_social.sql` 생성.
  - Enum 및 `social_interactions` 테이블 정의.
  - RLS 정책 적용.

- [x] **Step 2: 도메인 및 데이터 레이어 구현 (`minglit_kit`)**
  - `lib/src/data/models/social_interaction.dart` 모델 생성.
  - `lib/src/data/repositories/social_repository.dart` 구현.

- [x] **Step 3: 비즈니스 로직 및 상태 관리 (`minglit_kit`)**
  - `lib/src/features/social/logic/social_interaction_controller.dart` 구현 (Optimistic Update).

- [x] **Step 4: UI 컴포넌트 구현 (`minglit_kit`)**
  - `lib/src/features/social/ui/minglit_social_button.dart` 생성.
  - 좋아요(Heart), 구독(Bell/Star), 북마크(Bookmark) 아이콘 지원.

- [x] **Step 5: 앱 통합 (`app_user`, `app_partner`)**
  - `EventDetailScreen`에 좋아요 버튼 적용.
  - `PartnerDetailView`에 구독 버튼 적용.
  - `PartyListItem`에 좋아요 수 표시 (Partner App).
