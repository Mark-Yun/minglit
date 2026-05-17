# PRD: 환불 정책 이원화 (Refund Policy v2)

## Summary

환불 규칙을 **플랫폼 자동 환불**(grace period / cutoff / 파트너 귀책)과 **파트너 환불 요청**(자동 범위 밖) 두 트랙으로 이원화하고, 약관·DB·코드의 환불 규칙을 하나의 정책으로 통일한다. 전자상거래법 제17조 7일 청약철회권 준수.

## Motivation / Problem to Solve

- **약관-코드-DB 불일치 (#765)**: 약관은 "3일/2-1일/당일" 다단계, DB 정책은 `grace_period_hours=2 + cutoff_days=7`, 코드는 binary(전액/불가) — 셋이 모두 다름
- **전자상거래법 위반 가능성**: 제17조(청약철회) / 제18조(환불 처리 기한) 준수 미흡
- **유저 페인**: cutoff 지난 결제는 자동 환불 불가 + 파트너에 환불 요청할 경로 부재 → 고객센터 우회 발생
- **충동 결제 회복 기간 부족**: 현재 grace period 2시간은 결제 직후 일정 충돌 발견 시 짧음

## Goals

### Target Users

- **유저 (취소자)**: 결제 후 일정 변경/충돌 발생, 자동 환불 가능 여부를 명확히 확인
- **유저 (파트너 귀책 피해자)**: 파트너의 이벤트 취소/심사 거절 시 자동 환불
- **파트너**: 자동 환불 범위 밖 유저 요청을 앱에서 승인/거절

### Key Goals

- **P0**: 약관·DB·코드 환불 규칙을 단일 정책(grace 3시간 / cutoff 7일 / 파트너 귀책 100%)으로 통일
- **P0**: grace period 2시간 → 3시간 변경
- **P0**: 자동 환불 가능/불가 상태를 결제 전·후 UI 에서 명확히 노출
- **P0**: 자동 환불 불가 시 파트너 환불 요청 인앱 플로우 제공
- **P1**: 파트너 앱에 환불 요청 목록/상세/승인/거절 화면
- **P1**: 72시간 미응답 시 고객센터 자동 에스컬레이션

### Non-Goals

- **부분 환불 (tier 공제율)**: V2 는 binary 유지. 인터파크식 다단계는 유저 혼선 우려로 V3 검토
- **파트너 커스텀 정책**: Frip 패턴은 V3
- **실시간 채팅**: 환불 요청은 비동기 메시지 기반
- **자동 부분 환불 tier**: 정산 시스템 고도화 후 V3

## Product Principles

1. **법적 안전**: 전자상거래법 제17조 7일 청약철회권 준수. 제18조 환불 처리 기한 명시
2. **이원화 명확성**: 플랫폼 자동 처리 vs 파트너 위임 범위가 한눈에 보임
3. **투명성**: 결제 전·후 어디서든 환불 조건/금액/입금일을 동일 카피로 노출
4. **단순성**: binary 유지(전액/불가) + 파트너 요청 경로 추가. 다단계 공제율 도입 보류

## Technical Approach

- **화면 (유저)**: 구매 내역 카드(취소 버튼/환불 상태 라벨), 환불 확인 다이얼로그, 환불 요청 바텀시트(자동 불가), 환불 요청 결과 안내, 이벤트 상세의 환불 안내 시트
- **화면 (파트너)**: 환불 요청 목록, 환불 요청 상세 + 승인/거절
- **저장**: `refund_requests` 신규 테이블, `policies.refund` 정책 갱신, `event_applications.refund_status` 확장
- **외부 의존성**: PortOne(결제 취소), 푸시 알림, pg_cron(72h 미응답 에스컬레이션)
- **가드**: 유저는 자기 요청만 INSERT/SELECT. 파트너는 자기 이벤트 요청만 SELECT/UPDATE(status, responded_at, rejection_reason)

## User Journey

### Scenario 1: 자동 환불 가능 — 결제 후 3시간 내 취소 (CUJ 1-x)

유저가 구매 내역에서 "취소하기" 탭 → grace period 내 판정 → 환불 확인 다이얼로그 → 확정 시 PortOne 자동 취소.

### Scenario 2: 자동 환불 가능 — 이벤트 7일 전 취소 (CUJ 2-x)

cutoff 전이므로 동일한 환불 확인 다이얼로그 → 자동 환불 처리.

### Scenario 3: 자동 환불 불가 — 파트너 환불 요청 (CUJ 3-x)

grace period 초과 + cutoff 초과 상태에서 취소 시도 → "환불 가능 기간이 지났어요" 바텀시트 → 사유 선택 → 파트너에게 요청 전송.

### Scenario 4: 파트너의 환불 요청 처리 (CUJ 4-x)

파트너 앱 알림 → 환불 요청 상세 → 승인(자동 환불 실행) 또는 거절(사유 입력) → 유저에게 푸시.

### Scenario 5: 파트너 귀책 자동 환불 (CUJ 5-x)

파트너가 이벤트 취소/심사 거절 → 신청자 전원 100% 자동 환불 + 푸시 안내.

## Data Flow

### Scenario 1 / 2

구매 내역 카드 "취소하기" → 서버 자동 환불 가능 판정(`user-cancel-order`) → 가능 → 확인 다이얼로그 → 확정 → PortOne 결제 취소 → `event_applications.refund_status = completed` → 유저에 결과 안내

### Scenario 3

"취소하기" → `user-cancel-order` → 자동 환불 불가 응답(`{ type: 'partner_refund_available' }`) → 환불 요청 바텀시트 → 사유 선택 → `user-request-refund` EF → `refund_requests` INSERT → 파트너 푸시

### Scenario 4

파트너 알림 탭 → 환불 요청 상세 → 승인: `partner-approve-refund` → PortOne 취소 + status=approved → 유저 푸시. 거절: `partner-reject-refund` → status=rejected + rejection_reason → 유저 푸시

### Scenario 5

파트너 이벤트 취소/심사 거절 → 기존 batch refund 트리거 → 신청자 전원 자동 환불 + 푸시

## KPIs / Success Metrics

- **자동 환불 성공률**: PortOne 호출 성공 / 자동 환불 시도 ≥ 99%
- **환불 가능 안내 인지율**: 결제 전 환불 안내 시트 노출 → 결제 진행률(baseline 측정)
- **파트너 응답률**: 환불 요청 → 72시간 내 파트너 응답 ≥ 80%
- **고객센터 환불 문의 감소율**: V1 baseline 대비 30% 감소
- **약관-코드 일치 감사**: 다음 법무 감사에서 #765 close

## Launch Strategy

- 약관 변경은 backend 정책 + EF 배포와 같은 dev 사이클 내 동시 반영 (불일치 기간 0)
- 점진 출시 X — 정책 통일이라 전체 유저 일괄 적용

## Legal Basis

| 근거 | 내용 |
|------|------|
| 전자상거래법 제17조 | 청약철회권 7일 보장 |
| 전자상거래법 제18조 | 환불 처리 기한 (3영업일 내) |
| 전자상거래법 제15조 | 거래 조건의 명확한 고지 |
| 표준약관(공정거래위원회) | 환불 정책 게시 의무 |

## References

- **Frip**: 호스트 커스텀 정책 (V3 검토)
- **Airbnb Experiences**: grace period + cutoff 구조 (현행과 유사, V2 유지)
- **인터파크 티켓**: 다단계 tier (복잡도 대비 유저 혼선 우려, 채택 안 함)
- **이슈 #765**: 환불 정책 약관-코드 불일치 (원인 이슈)
