# Service Spec — minglit이 하는 일

> 사용자/Partner 양쪽 시점에서 minglit이 무엇을 제공하는지 정리.
> 도메인 용어 → [glossary.md](./glossary.md), Partner 운영 흐름 → [partner-workflow.md](./partner-workflow.md), 페르소나 → [personas.md](./personas.md), 미션/원칙 → [founding-story.md](./founding-story.md).

## 한 줄 정의

**minglit은 한국형 mid-market 만남 모임 플랫폼.** Partner가 이벤트를 운영하고, 사용자가 참가하고, 자동 매칭 + 결제·정산·검증을 minglit이 인프라로 처리.

---

## 1. 핵심 가치 제안

### 사용자 입장
- 검증된 사람들과 만나는 효율적 모임 (결정사 대비 부담 ↓, 데이팅앱 대비 신뢰 ↑)
- 한 번 가입 → 다양한 컨셉의 모임 (1 플랫폼 + N Partner 모델)
- 자동 매칭: mutual interest 시 연락처 자동 공유 (수동 교환 불필요)
- 플랫폼 보장 결제·환불 (환불 윈도우 내 자동 처리, 사용자 책임 X)

### Partner 입장
- 결제·정산·매칭·검증 인프라 자동화 → 컨셉/큐레이션에만 집중 ([partner-workflow.md §자동화](./partner-workflow.md) 참조)
- 진입 장벽 낮음: 이메일 + 전화 인증만으로 운영 즉시 시작 가능
- 정기 운영 자동화: RecurrenceRule로 반복 이벤트 자동 생성
- 수수료 10% = 인프라 비용의 전부 (결제 수수료 포함 minglit 부담)

---

## 2. 지원 이벤트 타입 (MVP)

### 2.1 로테이션 소개팅 / 미팅 (1차 GTM 타겟)
- 규모: 4:4 ~ 12:12
- EntryGroup: 보통 2개 (예: 남성/여성). Partner가 그룹 구조 자율 정의.
- 라운드: Partner 자율 진행 (10분 표준, 현장 운영은 Partner 책임 — [partner-workflow.md #7](./partner-workflow.md) 참조)
- 매칭: 이벤트 종료 후 MatchVote → mutual interest 검출 → 연락처 자동 공유
- 검증: Identity (필수) + Qualification (Partner 자율 정의)

### 2.2 일반 파티 (네트워킹 / 취미 모임)
- 규모: 자율. EntryGroup 수: Partner 선택 (1개 이상)
- 매칭 시스템: **Partner 선택 사항**. 미사용 시 RSVP + 체크인만.
- 원칙: "minglit은 툴 제공, 사용은 Partner에게 맡긴다"

### 2.3 향후 (Phase 2, 1–2년 후)
- 1:1 소개팅 (별도 이벤트 타입, 현재 미구현)
- 그 외 Partner 요청 기반 확장

---

## 3. 사용자 여정 (User Journey)

### 3.1 가입 & 본인인증
1. 이메일 / 소셜(Kakao·Apple·Google) 가입
2. PortOne PASS 본인인증 (Identity Verification — 모든 사용자 필수, [glossary.md #Identity-Verification](./glossary.md) 참조)
3. 인증 완료 → 추천 피드 접근 가능

### 3.2 이벤트 발견 & 신청
1. 추천 피드 (인기 기반 + pgvector 임베딩 개인화 + 태그 기반)
2. 이벤트 상세 → EntryGroup + Ticket 선택 → Application 생성
3. Partner Qualification 요구 시 → 자유폼 양식 작성 (텍스트 + 이미지/PDF)
4. 즉시 결제 (PortOne V1). 결제 완료 = Application 생성 완료.
5. Qualification 기통과자: 자동 참가 확정 / 미통과자: Partner 승인 대기

### 3.3 환불 윈도우
| 조건 | 처리 |
|------|------|
| 결제 후 2시간 이내 | 자동 환불 (cooling off) |
| 이벤트 시작 7일 전 이내 | 자동 환불 (청약철회) |
| 그 외 | 환불 불가 → 고객센터 안내 |
| 이벤트 취소 (Partner) | 전체 참가자 전액 자동 환불 |

No-show 정책: 환불 윈도우 내 신청 없이 미참가 → 환불 X. 상세 → [payment-domain.md §4](./payment-domain.md).

### 3.4 이벤트 참가
1. 당일 → QR 체크인 (Ed25519 서명 검증, Partner Staff 스캔)
2. 체크인 = 매칭 자격 게이트 + 정산 대상 동시 확정
3. 이벤트 진행 (Partner 주도)
4. 매칭 사용 이벤트: 종료 후 MatchVote → mutual → MatchPair 자동 생성 → 연락처 공유
5. 매칭 미사용 이벤트: 체크인 + 참가로 완료

---

## 4. Partner 여정 (Partner Journey)

### 4.1 가입 (Lean MVP)
- **최소 진입**: 이메일 + 전화 인증만 (5초 onboarding)
- 가입 즉시 Party 생성 + Event 등록 + 유료 이벤트 운영 가능
- 큐레이션: 자동 (Mark 수동 승인 없음). AI 워커 사후 모니터링 — [ai-first-principle.md](./ai-first-principle.md) 참조.
- "Verified" 배지: 없음 (신뢰는 escrow + Identity 인증으로 대체)

### 4.2 Escrow 모델 (먹튀 차단)
- 결제금은 즉시 Partner 입금 X → 14일 Hold
- 체크인된 결제건만 정산 산정 → No-show 결제 정산 제외
- 먹튀 시나리오 자동 차단 (체크인 없으면 정산 없음)

### 4.3 정산 인증 (첫 정산 시점)
- 첫 정산 시점에 추가 인증 필요:
  - 사업자등록 (또는 비사업자 처리)
  - 정산 계좌 (PortOne 파트너 ID 연결)
  - 본인 신원 (자금세탁방지)
- 미완료 시 정산 Hold 무한 대기. 사용자는 환불 윈도우 내 자동 환불 가능.

### 4.4 정기 운영
- RecurrenceRule로 이벤트 자동 반복 생성 (주/격주/월 단위)
- 최소 참여자 미달 시 다음 이벤트 이월: **미구현** — [partner-workflow.md §Feature-Gap](./partner-workflow.md) 참조

### 4.5 Staff 권한 모델
- **owner**: 모든 권한 (정산 계좌, Staff 관리)
- **manager**: Party/Event 생성·수정
- **staff**: 체크인 처리 + Application 승인/거부 (현장 실무)

자세한 Staff 구조 → [glossary.md #Staff](./glossary.md).

---

## 5. 매칭 시스템

### 5.1 사용자 → 이벤트 추천 (피드)
v1에 3가지 방식 병렬 적용:
- **인기 기반**: 참가자 ↑ 이벤트 우선 (신규 사용자 cold-start 대응)
- **pgvector 임베딩 기반**: 사용자 인터랙션(본 파티 + 신청한 파티) 가중치로 사용자 임베딩 계산 → 코사인 유사도 추천
- **태그 기반**: AI 자동 추출 태그 기반 집단 인기 트렌드 노출 (개인화 태그는 미래)

상세 → [glossary.md #Recommendation](./glossary.md) / [glossary.md #Tag](./glossary.md).

### 5.2 이벤트 내 참가자 ↔ 참가자 매칭
- **MatchVote**: 참가자가 마음에 든 상대 지목 (MatchRule이 허용하는 방향으로만)
- **MatchPair**: mutual interest 자동 검출 → 자동 생성 → 상호 연락처 공개
- **MatchRule**: Partner가 그룹 간 매칭 방향 정의 (예: A→B, B→A, vote_count 상한 설정)

자세한 로직 → [glossary.md #MatchRule](./glossary.md) / [#MatchVote](./glossary.md) / [#MatchPair](./glossary.md).

---

## 6. 결제 / 정산 / 환불 모델 (요약)

상세 → [payment-domain.md](./payment-domain.md).

| 항목 | 내용 |
|------|------|
| 결제 채널 | PortOne V1 (일반 결제) / V2 (본인인증 + 파트너 정산) |
| 수수료 | 10% 정률. 무료 이벤트 0%. VAT는 minglit 부담 (Partner 편의) |
| 정산 Hold | 14일 (전자상거래법 7일 + 운영 buffer 7일) |
| 정산 지급 | Hold 종료 시 PortOne API 자동 즉시 송금 (별도 신청 불필요) |
| Escrow 구조 | 체크인 완료 결제건만 정산 대상 |
| 환불 자동화 | 2시간 / 7일 윈도우 내 자동 처리 |

Partner 직접 결제 모드 (플랫폼 외 자체 채널): 환불 수동, minglit 정산 개입 없음 — [payment-domain.md §2](./payment-domain.md) 참조.

---

## 7. 검증 (Verification) 시스템

2-layer 구조:

| Layer | 명칭 | 주체 | 대상 | 의미 |
|-------|------|------|------|------|
| 1 | Identity Verification | minglit 표준 (PortOne PASS) | 모든 사용자 필수 | "실존 인물" 보장 |
| 2 | Qualification Verification | Partner 자유 정의 | 이벤트별 자율 | "이 모임에 맞는 사람" 보장 |

- Qualification 양식: Partner가 자유폼 정의 (string 텍스트 + 이미지/PDF)
- 양식 정의 → VerificationSubmission(제출) → Partner 검토 → 승인/거부 → Application 자동 전환

상세 → [glossary.md #Identity-Verification](./glossary.md) / [#Qualification-Verification](./glossary.md).

---

## 8. MVP 범위 vs Future

### MVP (2026-07 런칭 목표)
- 로테이션 소개팅 + 일반 파티 (매칭 옵션)
- 자동 추천 (인기 + 임베딩 + 태그)
- 플랫폼 결제 + 14일 Hold 자동 송금
- Identity + Qualification 검증
- Partner Lean onboarding (정산 시 추가 인증)
- RecurrenceRule 자동 반복

### Phase 2 (2026-08 ~ 12)
- 최소 참여자 미달 시 다음 이벤트 이월 (현재 미구현)
- 메시지 기능 (현재는 핸드폰번호 공유만)
- 외부 venue 플랫폼 연동 (스페이스클라우드) — [research/venue-rental-platforms.md](../research/venue-rental-platforms.md) 참조

### 미정 / 검토 중
- 1:1 소개팅 이벤트 타입 (1–2년 후)
- 정기 구독 모델
- 돌싱 / 재혼 시장 확대 (U-2 페르소나 — [personas.md](./personas.md) 참조)
- 결정사 매니저 위주 1:1 매칭 마켓
- Partner P-2(개인 호스트) → P-1(전문 사업자) 성장 경로 지원 강화

---

## 9. 운영 원칙

이 spec의 모든 결정은 다음에 부합:
- [founding-story.md](./founding-story.md) — Mission ("인연을 찾아가는 통과 입구") + 5-year vision
- [ai-first-principle.md](./ai-first-principle.md) — AI 워커 중심 운영, Mark 인간 게이트는 명확히 정의된 영역만
- 분업 원칙: "minglit = 인프라, Partner = 컨셉/큐레이션" ([product-thesis.md](./product-thesis.md) §분업-모델 참조)

---

## 10. 미해결 / Mark 결정 필요

- `<TODO: 환불 정책 약관 명시 — No-show 환불 X 정책이 약관에 현재 명시되어 있는지 확인 필요>`
- `<TODO: Verified badge UI 추가 검토 — 현재 없음, 사용자 신뢰 신호 강화 필요 시 재검토>`
- `<TODO: 큐레이션 자동 모니터링 + 위반 Partner 제재 흐름 정의 (AI 워커가 탐지 후 어디까지 자율 처리?)>`
- `<TODO: 통신판매업 신고 → 사이트 푸터 표시 등 행정 후속 처리>`
- `<TODO: Partner 직접 결제 모드에서 한국 소비자보호법 의무 적용 범위 — 변호사 자문 필요>`
