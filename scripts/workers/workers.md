# Workers

밍릿 프로젝트의 자동화 워커 시스템. launchd로 주기적 단발성 실행.

## 아키텍처

```
audit 워커 (5개)
  → 현재 코드/인프라 상태 평가 + 문제점 도출
  → docs/ 문서 관리의 주체
  → audit-report 라벨 이슈 생성
      │
      ▼
tpm-staff
  → audit-report 분석 + 수정 필요성 판단
  → actionable 이슈 생성 (issue-worker가 처리할 수 있는 수준)
      │
      ▼
issue-worker
  → bug/enhancement/refactor 이슈 처리
  → 코드 수정 + PR 생성
      │
      ▼
pr-care
  → 모든 열린 PR 모니터링
  → BEHIND 업데이트, 리뷰 대응, dependabot 처리
```

## 워커 목록

### Audit 워커 — 평가 + 문서 관리

현재 상태를 평가하고 문제점을 도출한다. `docs/` 문서 관리의 주체.

| 워커 | 주기 | 역할 | 문서 관리 |
|------|------|------|-----------|
| **audit-arch** | 24시간 | Feature 격리, 패턴 준수, 순환 의존성, 코드 중복 | `docs/architecture/`, `docs/features/`, `docs/debugging/` 최신화 + PR |
| **audit-bug** | 24시간 | null crash, 에러 삼킴, TODO/FIXME, 타입 안전성 | - |
| **audit-qa** | 24시간 | 일일 PR/버그 기반 테스트 보강 제안, 커버리지 현황 | `docs/qa/` 전체 최신화 + PR |
| **audit-security** | 24시간 | 인증 누락, RLS 미적용, 시크릿 노출, 의존성 취약점 | - |
| **audit-uiux** | 24시간 | 디자인 토큰 준수, golden test 커버리지, 접근성 | `docs/ux/` 전체 |

### 운영 워커

| 워커 | 주기 | 역할 |
|------|------|------|
| **issue-worker** | 10분 | 이슈 처리 (bug-report, bug, ci-failure, enhancement, refactor 라벨만) |
| **pr-care-worker** | 30분 | stale PR 케어 (BEHIND 업데이트, 코드리뷰 대응, dependabot close) |
| **tpm-staff** | 2시간 | audit-report → actionable 이슈 변환 (수정 필요성 판단 + 플랜 작성) |

## 라벨 체계

| 라벨 | 생성 주체 | 처리 주체 |
|------|----------|----------|
| `audit-report` | audit 워커 | tpm-staff |
| `audit-arch` | audit-arch | (분류용) |
| `audit-bug` | audit-bug | (분류용) |
| `audit-qa` | audit-qa | (분류용) |
| `audit-security` | audit-security | (분류용) |
| `audit-uiux` | audit-uiux | (분류용) |
| `bug-report` | 유저/앱 | issue-worker |
| `bug` | 수동 | issue-worker |
| `ci-failure` | CI notify | issue-worker |
| `enhancement` | 수동 | issue-worker |
| `refactor` | 수동/tpm | issue-worker |
| `ai-worker` | issue-worker | issue-worker (PR 케어) |

## 워커 행동 원칙

- 깃헙 이슈를 수정하고 코드 커밋 / PR 서브밋하는 **정상적인 방법으로만** 케어한다.
- `--admin` bypass, `--force` push, 직접 머지 등 **편법 금지**.
- PR은 CI 통과 + 리뷰 resolve 후 auto-merge로 머지.
- 이슈는 PR 머지 후 `Closes #이슈번호`로 자동 종료.

## 스케줄링

macOS launchd로 실행. plist 파일: `scripts/workers/launchd/`

```bash
# 설치
for plist in scripts/workers/launchd/*.plist; do
  cp "$plist" ~/Library/LaunchAgents/
  launchctl load ~/Library/LaunchAgents/$(basename "$plist")
done

# 상태 확인
launchctl list | grep com.minglit

# 특정 워커 수동 실행
bash scripts/workers/issue-worker-run.sh

# 로그 확인
ls /tmp/claude-worker-logs/
```

## 파일 구조

```
scripts/workers/
├── *-run.sh            # 단발성 실행 스크립트 (launchd가 호출)
├── prompts/            # claude -p 프롬프트
│   ├── audit-arch.txt
│   ├── audit-bug.txt
│   ├── audit-qa.txt
│   ├── audit-security.txt
│   ├── audit-uiux.txt
│   ├── issue-worker.txt
│   ├── pr-care-worker.txt
│   └── tpm-staff.txt
├── launchd/            # macOS LaunchAgent plist
│   └── com.minglit.*.plist
└── workers.md          # 이 문서
```
