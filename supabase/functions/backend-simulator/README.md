# backend-simulator

Stochastic Cascade 모델 기반 백엔드 시뮬레이터. 진입점 / 모드 / 컨벤션은 [BLUEDOC.md](./BLUEDOC.md), 아키텍처 상세는 [architecture.md](./architecture.md).

## 빠른 실행

```bash
# 단위 테스트
deno test action/ core/ policy/ invariant/ --allow-all

# EF 호출 (dev)
curl -X POST "https://<project>.supabase.co/functions/v1/backend-simulator" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"ticks": 3, "usersPerTick": 10}'
```

## 폴더

- `index.ts` — EF 진입점 (cascade 호출)
- `core/` — 엔진 (cascade, observable, trace, transport, snapshot, reporter, auth, types)
- `action/` — 8 액션 (apply/refund/checkin/discover/vote/block + partner_approve/reject/create_event)
- `policy/` — user/partner 가중 sampling
- `params/` — 확률 데이터 (default.ts)
- `invariant/` — cross-EF 규칙 (현재: blocking 1개, 점진 확장)

## 옛 코드와의 차이 (vs phase/tick 모드)

phase 모드 6단계 직렬 + tick 모드 actor factory 패턴은 v2 cascade 로 통합·삭제. 옛 sim_*.ts / tick/ 폴더는 본 PR 에서 제거.
