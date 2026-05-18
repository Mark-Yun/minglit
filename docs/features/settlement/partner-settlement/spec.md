# Spec: 파트너 정산

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs:
>   - [`settlement_page`](../../../../apps/mds/docs/public/specs/settlement_page/) — 정산 대시보드/목록/상세 (존재 여부 확인 필요)
>   - [`bank_account_page`](../../../../apps/mds/docs/public/specs/bank_account_page/) — 계좌 관리
> - 기존 문서: [requirements.md](./requirements.md), [architecture.md](./architecture.md), [ui-ux-design.md](./ui-ux-design.md)

## CUJs

> CUJ ID 컨벤션: `<scenario>-<cuj>`. 새 CUJ 추가 시 본 테이블 row 추가 + `apps/app_partner/integration_test/cuj/settlement/<feature>_test.dart` 의 `cujGroup` 블록 추가.

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 이벤트 완료 시 정산 레코드 자동 생성 | • 이벤트 `completed` 전환<br>• `on_event_completed` DB 트리거 실행<br>• `settlement_items` PENDING 생성<br>• 율 스냅샷 (수수료율·VAT) 저장<br>• 이중 생성 방지 (멱등성) | FR-1, FR-2, FR-3 | NFR-1, NFR-5 |
| 1-2 | P0 | 이벤트 완료 트리거 멱등성 보장 | • 동일 이벤트에 대해 트리거 재실행 시<br>• 정산 레코드 1건만 생성<br>• 이미 존재하면 중복 생성 없음 | FR-2 | NFR-5 |
| 2-1 | P0 | 14일 경과 시 PENDING → READY 전환 | • nightly cron 03:00 KST<br>• 14일 경과 PENDING 조회<br>• 체크섬 검증 통과 시 READY<br>• 검증 실패 시 FAILED + 운영 알림 | FR-4, FR-5 | NFR-2, NFR-4 |
| 2-2 | P0 | READY 배치 지급 → COMPLETED | • 배치가 READY 항목 수집<br>• PortOne Payout API 호출<br>• 성공 시 COMPLETED + 원장 기록 | FR-6, FR-7 | NFR-2, NFR-3 |
| 2-3 | P0 | 지급 실패 지수 백오프 재시도 | • PortOne 오류 → FAILED<br>• 재시도 가능 오류: 지수 백오프 (max 8회)<br>• 비재시도 오류: HOLD + 운영 알림 | FR-8, FR-9 | NFR-3 |
| 3-1 | P0 | 파트너가 정산 요약 KPI 조회 | • 앱 정산 페이지 진입<br>• 총 정산 금액·수수료·입금 예정 카드<br>• 상태별 분류 (PENDING/READY/COMPLETED) | FR-10 | NFR-1 |
| 3-2 | P0 | 이벤트별 정산 목록 조회 | • 이벤트명·상태·금액 리스트<br>• 상태 뱃지 시각화<br>• 정산 상세로 진입 | FR-11 | NFR-1 |
| 3-3 | P0 | 정산 상세 (수수료 내역·타임라인) | • 수수료율·공제액·최종 정산액 표시<br>• 7-상태 타임라인 UI<br>• 입금 예정일 안내 | FR-12, FR-13 | NFR-1 |
| 3-4 | P1 | 정산 이의 제기 | • HOLD 상태 정산에서 이의 제기 탭<br>• 사유 입력 → 운영팀 알림<br>• 이의 제기 내역 조회 가능 | FR-14 | NFR-1 |
| 3-5 | P1 | 정산 PDF 다운로드 | • 정산 상세에서 PDF 다운로드<br>• 정산 내역·서명·수수료 포함 | FR-15 | NFR-1 |
| 4-1 | P0 | 지급 실패 항목 재시도 (시스템) | • 재시도 가능 FAILED 항목<br>• `next_retry_at` 경과 시 자동 재시도<br>• max 8회 초과 시 HOLD | FR-8 | NFR-3 |
| 5-1 | P0 | 파트너가 정산 계좌 등록 | • bank_account_page 진입<br>• 은행·계좌번호·예금주 입력<br>• 인증(PortOne 1원 인증 또는 KYC) | FR-16 | NFR-1 |
| 5-2 | P0 | 파트너가 정산 계좌 변경 | • 기존 계좌 변경 요청<br>• 변경 후 다음 배치부터 새 계좌 적용 | FR-16 | NFR-1 |

## Functional Requirements

> 제품 행동 정의 — DB schema SQL / Provider 이름 / 메서드 시그니처 같은 dev detail 은 제외.

- **FR-1**: 이벤트 상태가 `completed`로 전환될 때 DB 트리거(`on_event_completed`)가 정산 레코드를 자동으로 PENDING 상태로 생성. 수동 개입 없음. 결제 승인은 선행 조건(티켓 발권)이며 정산 직접 트리거가 아님.
- **FR-2**: 동일 이벤트에 대해 정산 레코드는 1건만 생성 (멱등성). 트리거 재실행 시 이미 존재하면 중복 생성 없음.
- **FR-3**: 정산 생성 시 수수료율·VAT율을 스냅샷으로 저장. 이후 율 변경이 기존 정산에 영향 없음.
- **FR-4**: nightly cron(03:00 KST)이 `event_completed_at + 14일 ≤ now()`인 PENDING 레코드를 READY로 전환. 전환 전 필수 필드 + 체크섬 검증 통과 필수.
- **FR-5**: 체크섬 검증 실패 시 FAILED 전환 + 운영 알림. 항목 무결성이 확인되기 전에 지급 불가.
- **FR-6**: READY 상태 항목을 파트너·기간별로 묶어 배치 지급 실행. 배치 생성 시 은행 계좌 스냅샷 저장.
- **FR-7**: PortOne Payout API 호출. 성공 시 COMPLETED + 원장 기록. 단일 실행 락(CAS)으로 중복 지급 방지.
- **FR-8**: 재시도 가능 오류 발생 시 지수 백오프(`min(2^n * 60s, 6h) + ±20% jitter`)로 재시도. 최대 8회.
- **FR-9**: 비재시도 오류 발생 시 HOLD 전환 + 운영 알림. 운영자가 원인 해결 후 수동 재시도 가능.
- **FR-10**: 파트너 정산 페이지에서 총 정산 금액·수수료 합계·입금 예정액 KPI 카드 노출.
- **FR-11**: 이벤트별 정산 목록에 이벤트명·상태 뱃지·정산 금액 노출. 상태별 필터 가능.
- **FR-12**: 정산 상세에서 수수료율·공제액·최종 정산액·세부 내역 노출.
- **FR-13**: 정산 상태 타임라인(PENDING → READY → COMPLETED 등) 및 입금 예정일 노출.
- **FR-14**: HOLD 상태 정산에서 이의 제기 기능. 사유 필수 입력. 제출 후 운영팀 검토 진행.
- **FR-15**: 정산 상세에서 PDF 다운로드. 정산 내역·수수료·날인 포함.
- **FR-16**: 파트너가 정산 계좌(은행·계좌번호·예금주)를 등록·변경 가능. 변경 후 다음 배치부터 새 계좌 적용.

## Non-Functional Requirements

> 측정 가능해야 함 — 환경 + 분위수 명시.

- **NFR-1**: 정산 페이지 진입 → first paint 1s 이내 (에뮬레이터 baseline, p50). 목록/상세 fetch ≤ 1.5s (p95).
- **NFR-2**: nightly cron 1회 실행에서 1,000건 이하 처리 ≤ 5분 (p95). 초과 시 다음 회차로 분할.
- **NFR-3**: 지급 실패 재시도: 재시도 가능 오류 → 8회 이내 완료 p90. COMPLETED 최종 성공률 ≥ 99.5%.
- **NFR-4**: 체크섬 실패율: PENDING → READY 전환 중 데이터 무결성 실패 < 0.1% (monthly).
- **NFR-5**: 정산 레코드 중복 생성: 0건 (동일 결제 건 기준, monthly audit 기준). 멱등성 위반 즉시 알림.

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | 이벤트 완료 시 DB 오류 | 트랜잭션 롤백 → 이벤트 상태 변경도 함께 롤백. 재시도 시 트리거 재실행 |
| 1-2 | 동일 이벤트 트리거 재실행 | 멱등성 보장 — 정산 레코드가 이미 존재하면 생성 없이 정상 종료 |
| 2-1 | 파트너 계좌 미등록 상태에서 READY 전환 시도 | 체크섬 실패 → FAILED + 운영 알림 |
| 2-2 | PortOne API 타임아웃 | FAILED 전환 + 재시도 스케줄 |
| 2-3 | 재시도 8회 모두 실패 | HOLD 전환 + 운영 알림 (비재시도 오류와 동일 처리) |
| 3-1 | 정산 0건인 파트너 | 빈 상태 안내 (데이터 없음) |
| 3-3 | PROCESSING 상태 항목 조회 | 현재 처리 중 상태 + 예상 완료 시각 안내 |
| 4-1 | `next_retry_at` 도달 전 수동 재시도 시도 (Admin) | 가드 차단 + 예약 시각 안내 |
| 5-2 | 계좌 변경 중 진행 중인 PROCESSING 항목 | 기존 계좌로 지급 완료 후 변경 적용 |

## Open Questions

> 결정 못한 항목 — 1주 이상 방치 시 결정 또는 Non-Goal 이동.

- [ ] **이의 제기 SLA** — 운영팀이 이의 제기 처리하는 목표 기한? (24h? 3일?)
- [ ] **정산 PDF 포함 항목** — 세금계산서 대체 효력 범위? 법무 확인 필요.
- [ ] **파트너 계좌 인증 방식** — PortOne 1원 인증 vs 서류 제출? 현재 구현 방식 확인 필요.
- [ ] **nightly cron 실패 시 SLA** — cron 실패 → 익일 재실행 vs 수동 트리거? 지연 보상 정책?

---

## 화면 구성 (참고)

> dev detail 제외. 코드: `apps/app_partner/lib/src/features/settlement/`

### settlement_page.dart — 탭 구조

1. **대시보드 탭** (`_settlement_dashboard_tab.dart`): KPI 카드(총 정산·수수료·입금 예정) + 상태별 집계 + 수익 트렌드 차트
2. **목록 탭** (`_settlement_list_tab.dart`): 이벤트별 정산 목록 (상태 뱃지·금액·날짜)
3. **상세 페이지** (`settlement_detail_page.dart`): 수수료 내역·타임라인·이의 제기·PDF 다운로드

### 정산 상태 뱃지 시각화

| 상태 | 뱃지 색 | 의미 |
|------|---------|------|
| PENDING | 회색 | 유예 기간 대기 중 |
| READY | 파란색 | 지급 배치 대기 |
| PROCESSING | 주황색 | 지급 실행 중 |
| COMPLETED | 초록색 | 입금 완료 |
| FAILED | 빨간색 | 오류 — 재시도 예정 |
| HOLD | 노란색 | 홀드 — 운영 검토 필요 |
| CANCELED | 회색(취소선) | 지급 제외 |
