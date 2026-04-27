---
source_url: https://github.com/Mark-Yun/minglit/issues/1765
captured_at: 2026-04-23
issue_number: 1765
state: closed
labels: [report-runtime-qa]
author: Mark-Yun
title: "🐛 [HARD BLOCK] Flutter SDK missing in runtime environment"
---

# 🐛 [HARD BLOCK] Flutter SDK missing in runtime environment

> Issue #1765 · closed · created 2026-04-23T03:01:51Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1765

## Body

Scheduler: runtime-qa-smoke-partner-gemini

## 현상
- `flutter` 명령어가 PATH에 없음.
- `dart` MCP 서버가 `Flutter SDK location unknown` 에러를 반환함.
- `dart pub get` 시 Flutter SDK가 없어 종속성 해결 실패 (Exit 69).

## 영향
- 프로토콜상 필수인 '앱 빌드 & 설치' 단계를 수행할 수 없음.
- 최신 코드가 반영되지 않은 구버전 앱으로 QA를 진행하게 될 리스크가 있어 작업을 중단함.

## 재현 방법
```bash
flutter --version
# Output: bash: flutter: command not found
```

## 제안
- 워커 이미지/환경에 Flutter SDK를 설치하고 PATH 및 `FLUTTER_SDK` 환경변수를 설정해야 함.

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-23

🤖 **needs-tpm-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-23

🤖 **needs-tpm-claude-1** 트리아지 완료.

**결론: 중복 — #1713으로 통합**

동일한 현상이 이미 #1713 (2026-04-22)로 보고되어 있으며, `P1-high + report-exec` 라벨로 Mark 판단 대기 중입니다.

#1713 에서 제시한 옵션:
- A) runtime 환경에 Flutter SDK 설치 (모드 B 지원)
- B) 모드 B를 polling 대신 on-demand로 전환
- C) 모드 B 제거하고 모드 A (이슈 재현) 만 유지

이번 보고 (`runtime-qa-smoke-partner-gemini`)는 동일 문제가 partner 스모크에서도 재현됨을 확인해준 것으로, 영향 범위가 user/partner 양쪽 runtime-qa 모두에 걸쳐 있음을 확인합니다. 이 사실을 #1713 본 스레드에 추가 기록하고 본 이슈는 중복으로 닫습니다.

Closes as duplicate of #1713.
