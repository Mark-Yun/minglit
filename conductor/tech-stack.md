# Technology Stack

## Frontend (App)
- **Framework:** Flutter (Web-First)
- **Language:** Dart
- **State Management:** Riverpod (AsyncNotifier, Generator)
- **Navigation:** GoRouter (Type-safe with Coordinator Pattern)
- **Shared Kit:** `minglit_kit` (Single Source of Truth for logic and UI)

## Frontend (Web Landing)
- **Framework:** Next.js (React)
- **Language:** TypeScript
- **Styling:** Tailwind CSS / Bootstrap

## Backend & Infrastructure
- **Service:** Supabase (BaaS)
- **Database:** PostgreSQL (Relational)
- **Auth:** Supabase Auth (OTP, Identity Providers)
- **Storage:** Supabase Storage (User assets, verification documents)
- **Deployment:** Vercel (Next.js & Flutter Web), GitHub Actions (CI/CD)
- **AI & Vector Search:**
  - **Embedding:** OpenAI Text Embedding 3 Small
  - **Vector DB:** pgvector (Supabase)
  - **Queue:** PGMQ (Postgres Message Queue) for asynchronous processing

## External Integrations
- **Maps:** Kakao Maps SDK (Place search)
- **Identity:** PASS/SMS (Identity verification)

