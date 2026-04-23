# 파트너 QR 체크인 UX 강화 — 테스트 계획

**관련 이슈**: #1779
**관련 PR (spec/wireframe)**: #1782
**작성자**: needs-qa-claude-1
**작성일**: 2026-04-24

## 대상 코드

spec.md의 구현 이슈 분할(1~7) 기준. 신규/변경 예상 파일:

### Backend
- `supabase/migrations/2026xxxx_add_checked_in_at.sql` — `event_participants.checked_in_at timestamptz`
- `supabase/migrations/2026xxxx_get_event_checkin_stats.sql` — RPC 신규
- Checkin EF (기존 `partner-checkin` 또는 현재 checkin repository가 호출하는 경로) — `status = 'checked_in'` + `checked_in_at = now()` 업데이트

### Frontend (app_partner)
- `apps/app_partner/lib/src/features/checkin/qr_scanner_screen.dart` — 레이아웃 리팩터 (카메라 220, 상단/하단 공간)
- `apps/app_partner/lib/src/features/checkin/widgets/checkin_summary_card.dart` — 신규 (요약 카드)
- `apps/app_partner/lib/src/features/checkin/widgets/entry_group_progress_sheet.dart` — 신규 (엔트리 그룹 시트)
- `apps/app_partner/lib/src/features/checkin/widgets/manual_checkin_sheet.dart` — 신규 (수동 체크인)
- `apps/app_partner/lib/src/features/checkin/checkin_stats_controller.dart` — 신규 (stats provider, Realtime 구독)
- `apps/app_partner/lib/src/features/checkin/checkin_controller.dart` — 스캔 성공 시 엔트리 그룹/N번째 표기 추가

### Shared
- `shared/packages/minglit_kit/lib/src/data/repositories/checkin_repository.dart` — `fetchCheckinStats`, Realtime 구독 헬퍼

## 테스트 계층별 계획

### Layer 1: pgTAP (DB 스키마 + RPC)

| 대상 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `checked_in_at` 컬럼 | `checked_in_at_column_test.sql` | 3건 | P1 |
| `get_event_checkin_stats` RPC | `get_event_checkin_stats_test.sql` | 7건 | P1 |
| 체크인 시 `checked_in_at` 업데이트 (trigger 또는 EF) | `checkin_update_behavior_test.sql` | 4건 | P1 |

#### `checked_in_at` 컬럼

```
1. 컬럼 존재 확인 — event_participants.checked_in_at timestamptz NULL 허용
2. 기본값은 NULL (신규 row 삽입 시)
3. 인덱스 존재 — (event_id, checked_in_at) 복합 (stats 조회 성능 P1)
```

#### `get_event_checkin_stats(p_event_id uuid)` RPC

```
1. happy path — 엔트리 그룹 3개 이벤트, 각 그룹별 total/checked_in 반환
2. 엔트리 그룹 없는 이벤트 — 빈 배열 반환 (전체 stats만)
3. 존재하지 않는 event_id — 에러 또는 빈 결과 (명세 확정 필요 → PR에서 합의)
4. 권한 — 이벤트 소유자 아닌 파트너 호출 시 거부 (RLS/SECURITY DEFINER)
5. checked_in 0명 — 모든 그룹 `checked_in: 0`
6. 환불된 티켓 — stats total 계산에서 제외 (participant status = refunded)
7. 전체 요약 — total_issued / total_checked_in 정확
```

#### 체크인 시 업데이트 동작

```
1. pending → checked_in 전환 시 checked_in_at = now() 설정
2. 이미 checked_in인 경우 재호출 시 checked_in_at 변경 없음 (idempotent)
3. refunded 티켓 체크인 시도 → 에러 + checked_in_at 미변경
4. 다른 이벤트 QR → 에러 + checked_in_at 미변경
```

### Layer 2: Edge Function 테스트 (Deno)

기존 체크인 EF에 변경이 있을 경우 regression 테스트 추가. 신규 EF는 없음.

| 대상 | 테스트 케이스 | 우선순위 |
|------|-------------|---------|
| 기존 checkin verify/update EF | 3건 (regression) | P1 |

```
1. 유효 QR → checked_in + checked_in_at 기록 (기존 결과 유지)
2. 중복 QR → "이미 체크인됨" + checked_in_at 최초값 유지
3. 다른 이벤트 QR → 403 + DB 변경 없음
```

### Layer 3: Widget 테스트 (Flutter)

| 위젯 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `CheckinSummaryCard` | `checkin_summary_card_test.dart` | 6건 | P1 |
| `EntryGroupProgressSheet` | `entry_group_progress_sheet_test.dart` | 7건 | P1 |
| `ManualCheckinSheet` | `manual_checkin_sheet_test.dart` | 5건 | P2 |
| `QRScannerScreen` (layout regression) | `qr_scanner_screen_test.dart` | 4건 | P1 |

#### CheckinSummaryCard

```
1. stats 있음 — 23/50, progress bar 46%, 남은 인원 27 렌더링
2. stats 로딩 중 — shimmer placeholder 노출, 숫자 영역 미노출
3. stats 에러 — "불러오기 실패 · 재시도" 링크 노출
4. 참가자 0명 — 0/0 + progress bar 0%, 빈 상태 메시지
5. 100% 완료 — progress bar full, "완료" 뱃지
6. 탭 시 onTap 콜백 호출 (v2 참가자 리스트 진입점)
```

#### EntryGroupProgressSheet

```
1. 엔트리 그룹 3개 — 각 그룹 label, count, progress bar 렌더링
2. 엔트리 그룹 0개 — 섹션 자체 숨김 (SizedBox.shrink)
3. 진행률 30% — primary 색상 progress bar
4. 진행률 70% — warning 색상 progress bar
5. 진행률 95% — error 색상 progress bar (임계치 경고)
6. 축소 상태 — 헤더 40px만 노출, 탭 시 확장
7. 로딩 실패 — "불러오기 실패" 메시지 (QR 스캔은 방해하지 않음)
```

#### ManualCheckinSheet

```
1. 참가자 리스트 렌더링 (approved 상태만)
2. 이름 검색 — 입력 시 리스트 필터링
3. 체크인 토글 — checked_in 상태로 변경 + 리스트 갱신
4. 이미 체크인된 참가자 — "체크인됨 HH:mm" 비활성 표시
5. 빈 검색 결과 — "검색 결과 없음" 메시지
```

#### QRScannerScreen 레이아웃 회귀

```
1. 이벤트 + stats 주입 시 SummaryCard, 카메라 프레임(220px), 바텀시트 모두 렌더링
2. stats provider error — SummaryCard는 에러 상태, 카메라는 정상 동작 (회귀 방지)
3. 플래시 토글 — CheckinController.toggleFlash 호출
4. 수동 체크인 버튼 — ManualCheckinSheet modal 오픈
```

### Layer 4: Golden 테스트 (시각적 회귀)

| 화면 | 파일 | 변형 | 우선순위 |
|------|------|------|---------|
| QR 스캐너 전체 화면 | `qr_scanner_screen_golden_test.dart` | 4건 | P2 |
| CheckinSummaryCard | `checkin_summary_card_golden_test.dart` | 3건 | P2 |
| EntryGroupProgressSheet | `entry_group_progress_sheet_golden_test.dart` | 3건 | P2 |

#### QRScannerScreen 골든

```
1. 기본 상태 (stats 로드됨, 엔트리 그룹 3개, 축소)
2. 바텀시트 확장 상태
3. 엔트리 그룹 없는 이벤트 (SummaryCard만)
4. 다크모드 (라이트의 기본 상태와 동일 레이아웃 확인)
```

#### CheckinSummaryCard 골든

```
1. 진행 중 (46%) — 라이트
2. 완료 (100%) — 라이트
3. 빈 상태 (0/0) — 라이트
```

#### EntryGroupProgressSheet 골든

```
1. 확장, 3 그룹 혼합 (0~50%, 50~90%, 90%+)
2. 확장, 쿼터 도달 (전부 100%)
3. 축소 상태 (헤더만)
```

### Layer 5: Integration / Patrol 테스트

| 시나리오 | 파일 | 우선순위 |
|---------|------|---------|
| CUJ-P03 체크인 플로우 확장 | `patrol_cuj_partner_checkin_test.dart` | P2 |

```
1. 대시보드 → 체크인 진입 → 스캐너 화면 SummaryCard/엔트리 그룹 렌더링
2. QR 스캔 성공 mock — SummaryCard 카운트 +1 즉시 반영
3. 수동 체크인 플로우 — 버튼 → 시트 → 이름 검색 → 체크인
```

**주의**: 카메라 하드웨어 의존은 mock으로 우회 (`CheckinController.processQR` 직접 호출). Patrol 환경에서 실제 카메라 권한 팝업은 SKIP.

### Layer 6: Realtime 동작 검증 (수동 + 자동화)

다른 기기에서 체크인 시 현재 기기에 반영되는지.

```
1. (자동) stats provider unit test — Realtime payload 수신 시 state 갱신
2. (수동) 기기 A에서 체크인 → 기기 B의 SummaryCard가 3초 내 갱신
3. (수동) 네트워크 끊김 → Realtime 재연결 시 stats 재조회 (invalidate)
```

## CUJ-P03 카탈로그 업데이트

`docs/qa/test-cases/cuj-partner.md` CUJ-P03 섹션 보강:

- Step 2 기대결과에 "SummaryCard (N/M) + 엔트리 그룹 섹션 진입 시 가시" 추가
- 새 Step: "바텀시트 pull-up → 그룹별 현황 확인"
- 새 Step: "수동 체크인 버튼 → 이름 검색 → 체크인"
- 새 변형 P03-V3: QR 스캔 성공 → SummaryCard 카운트 즉시 +1 반영
- 새 변형 P03-V4: 엔트리 그룹 쿼터 도달 (14/14) → 해당 그룹 progress bar error 색상

## 엣지 케이스 체크리스트 (regression 방지)

- [ ] 이벤트에 엔트리 그룹이 없음 → 하단 시트 섹션 숨김, SummaryCard는 정상
- [ ] 참가자 0명 → `0/0` + 스캐너 정상 동작 (스캔 시 에러)
- [ ] 환불된 티켓 재스캔 → 기존 에러 유지 + stats 변경 없음
- [ ] 다른 이벤트 티켓 → 기존 에러 유지
- [ ] 중복 체크인 → "이미 HH:mm 체크인됨" (체크인 시각 표기는 신규)
- [ ] stats RPC 실패 → SummaryCard 에러 상태, 스캐너/체크인은 정상 (격리)
- [ ] 오프라인 — v1 스코프 아님, stats 마지막 값 유지 + "오프라인" 뱃지만 확인 (v2에서 큐 구현)
- [ ] Realtime 구독 실패 → polling fallback (10s 간격) 또는 수동 새로고침

## 이슈 분할 (QA 작업 분배)

| 순서 | 제목 | 테스트 수 | 우선순위 | 선행 조건 |
|------|------|----------|---------|----------|
| 1 | test(db): get_event_checkin_stats RPC + checked_in_at 컬럼 pgTAP | 14건 | P1 | spec#1 머지 |
| 2 | test(ef): checkin regression (checked_in_at 업데이트) | 3건 | P1 | spec#2 머지 |
| 3 | test(widget): CheckinSummaryCard + EntryGroupProgressSheet | 13건 | P1 | spec#4, #5 머지 |
| 4 | test(widget): QRScannerScreen 레이아웃 회귀 + ManualCheckinSheet | 9건 | P1/P2 | spec#3, #6 머지 |
| 5 | test(golden): QR 스캐너 + 카드 + 시트 골든 | 10건 | P2 | spec#5 머지 |
| 6 | test(patrol): CUJ-P03 확장 flow | 3건 | P2 | spec#7 머지 |
| 7 | test(qa): Realtime payload unit + 수동 검증 노트 | 1건 + 수동 | P2 | spec#7 머지 |
| 8 | docs(qa): cuj-partner.md CUJ-P03 보강 | — | P1 | 본 PR |

## 실행 순서

```
P1 (필수, 구현과 병행): pgTAP 14 + EF 3 + 위젯 22 = 39건
P2 (권장, 구현 완료 후): 골든 10 + Patrol 3 + Realtime 1 = 14건
────────────────────────────────────────
총 53건 + CUJ-P03 카탈로그 업데이트 1건
```

## 리스크 / Open Questions

- **Realtime vs polling**: Realtime 구독이 flaky할 수 있음 → polling fallback 스펙이 spec.md에 명시 안 됨. 구현 시 ux-designer / swe 와 재확인.
- **엔트리 그룹 멤버십 산정**: 한 유저가 여러 그룹 기준을 충족할 때 stats에서 어느 그룹으로 카운트되는지 명세 필요. RPC 구현 시 `assigned_entry_group_id`(기존 컬럼 여부 확인) 기준이 자연스러움.
- **카메라 프레임 축소(250→220)**: 기존 CUJ-P03 스모크(P-S 파트너 스모크) 골든이 있다면 업데이트 필요. 본 PR 범위에서는 신규 위젯 골든만 커버.
- **v2 오프라인 큐**: v1 범위 아님. 테스트 케이스는 v2 피처 이슈 생성 시 별도 test-plan에 작성.

## 참고

- 스펙: `docs/features/partner-qr-checkin-ux/spec.md`
- 와이어프레임: `docs/features/partner-qr-checkin-ux/wireframe.html`
- QA 전략: `docs/qa/test-strategy.md`
- CUJ 카탈로그: `docs/qa/test-cases/cuj-partner.md` (CUJ-P03)
- 기존 체크인 컨트롤러: `apps/app_partner/lib/src/features/checkin/checkin_controller.dart`
- 기존 스캐너: `apps/app_partner/lib/src/features/checkin/qr_scanner_screen.dart`
