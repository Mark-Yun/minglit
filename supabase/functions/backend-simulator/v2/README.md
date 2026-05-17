# v2 PoC

[architecture.md](../architecture.md) 의 **Stochastic Cascade** 모델 PoC.

## 상태

- ✅ 스켈레톤 + 타입 정의
- ✅ 단위 테스트
- ✅ PoC: in-memory mock transport 로 cascade 1-step 동작 검증
- ⏳ 실 EF 연결 (modes/tick.ts) — 별도 단계
- ⏳ 8 액션 전체 마이그 — 별도 단계
- ⏳ invariant 라이브러리 확장 — 별도 단계

## 폴더

```
v2/
├── core/         # cascade 엔진 (types, observable, trace, cascade)
├── action/       # EF 별 transition 정의 (현재: apply 만)
├── policy/       # actor 의사결정 (현재: user, partner stub)
├── params/       # 확률 파라미터
├── invariant/    # cross-EF 규칙 (현재: blocking 1개)
└── modes/        # 호출 패턴 (현재: tick stub)
```

## 마이그 방향

PoC 검증 후 본 디렉토리는 backend-simulator 루트로 promote (현 tick/ 와 sim_*.ts 는 삭제). 단계는 [architecture.md Part 4](../architecture.md#part-4--마이그레이션-단계-roi-순) 참조.
