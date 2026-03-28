# Workers

밍릿 프로젝트의 자동화 워커 시스템. launchd로 주기적 단발성 실행.

## 아키텍처

```
audit 워커 (6개)
  → 현재 코드/인프라 상태 평가 + 문제점 도출
  → docs/ 문서 관리의 주체
  → audit-report 라벨 이슈 생성
      │
      ▼
tpm-staff (안을 봄)
  → audit-report 분석 + actionable 이슈 생성
  → 이슈 품질 관리 + 우선순위 조정
  → 구조적 문제 → report-exec
      │
      ▼
issue-worker
  → 이슈 처리 (코드 수정 + PR)
  → PR 케어 (BEHIND 업데이트, 리뷰 대응, dependabot)
      │
pm-staff (밖을 봄)
  → 시장/경쟁/기술 트렌드 조사
  → 기능 완성도 검증
  → 기능 제안/기술 추천 → report-exec
```

## 워커 간 상호작용

`worker-routing.json`에 정의된 라벨 기반으로 워커끼리 작업을 주고받는다.

```
예시 흐름:
issue-worker가 UI 문서 부족 발견
  → needs-uiux 라벨 + 코멘트
  → audit-uiux가 다음 사이클에서 감지 → 문서 보강
  → needs-uiux 제거 + needs-qa 추가 (테스트 필요하면)
  → audit-qa가 처리
```

| 라벨 | 담당 워커 | 설명 |
|------|----------|------|
| `needs-pm` | pm-staff | 피처 기획 요청 |
| `needs-arch` | audit-arch | 아키텍처 문서/분석 요청 |
| `needs-uiux` | audit-uiux | UI/UX 문서/디자인 요청 |
| `needs-qa` | audit-qa | 테스트 보강 요청 |
| `needs-security` | audit-security | 보안 검토 요청 |
| `needs-legal` | audit-legal | 법률/개인정보 검토 요청 |

## 워커 목록

### Audit 워커 — 평가 + 문서 관리

현재 상태를 평가하고 문제점을 도출한다. `docs/` 문서 관리의 주체.

| 워커 | 스케줄 (KST) | 역할 | 문서 관리 |
|------|-------------|------|-----------|
| **audit-arch** | 매일 09:00 | Feature 격리, 패턴 준수, 순환 의존성, 코드 중복 | `docs/architecture/`, `docs/features/`, `docs/debugging/` |
| **audit-bug** | 매일 13:00 | null crash, 에러 삼킴, TODO/FIXME, 타입 안전성 | - |
| **audit-qa** | 매일 17:00 | 일일 PR/버그 기반 테스트 보강 제안, 커버리지 현황 | `docs/qa/` |
| **audit-security** | 매일 21:00 | 인증 누락, RLS 미적용, 시크릿 노출, 의존성 취약점 | - |
| **audit-uiux** | 매일 01:00 | 디자인 토큰 준수, golden test, 접근성, UI 개선 제안 | `docs/ux/` |
| **audit-legal** | 매주 월 05:00 | 법률/개인정보보호법 취약점, 약관/처리방침 검토 | report-exec |

### Staff — 관리/기획

| 워커 | 스케줄 | 역할 |
|------|--------|------|
| **tpm-staff** | 4시간마다 | 안을 봄 — audit→actionable 이슈 + 이슈 품질 관리 + 운영 분석 + report-exec |
| **pm-staff** | 매일 17:00 | 밖을 봄 — 시장/기술 트렌드 + 기능 완성도 검증 + 기능 제안 → report-exec |

### 실행 워커

| 워커 | 스케줄 | 역할 |
|------|--------|------|
| **issue-worker** | 10분마다 | 이슈 처리 + PR 케어 (BEHIND 업데이트, dependabot, 리뷰 대응) |

## 라벨 체계

| 라벨 | 생성 주체 | 처리 주체 |
|------|----------|----------|
| `audit-report` | audit 워커 | tpm-staff |
| `report-exec` | tpm-staff, pm-staff, audit-uiux, audit-legal | 사람 (Mark) |
| `needs-*` | 모든 워커 | 해당 전문 워커 |
| `bug-report` | 유저/앱 | issue-worker |
| `bug` | 수동/tpm | issue-worker |
| `ci-failure` | CI notify | issue-worker |
| `enhancement` | 수동/tpm | issue-worker |
| `refactor` | 수동/tpm | issue-worker |

## 공통 프롬프트

| 파일 | 적용 대상 | 내용 |
|------|----------|------|
| `prompts/direction.txt` | staff만 (pm, tpm) | 프로젝트 디렉션 (출시 목표, 우선순위) |
| `prompts/worker-common.txt` | 전체 워커 | 워커 간 상호작용 프로토콜 (라벨 라우팅) |

## 워커 행동 원칙

- 정상적인 방법으로만 케어 (코드 수정 → PR → CI 통과 → auto-merge).
- `--admin` bypass, `--force` push, 직접 머지 등 **편법 금지**.
- 이슈는 PR 머지 후 `Closes #이슈번호`로 자동 종료.
- 다른 전문가의 조언이 필요하면 이슈에 코멘트 + `needs-*` 라벨로 라우팅.

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
├── *-run.sh              # 단발성 실행 스크립트 (launchd가 호출)
├── worker-routing.json   # 라벨 기반 라우팅 테이블
├── prompts/
│   ├── direction.txt     # 공통 디렉션 (staff만)
│   ├── worker-common.txt # 공통 상호작용 프로토콜 (전체)
│   ├── audit-arch.txt
│   ├── audit-bug.txt
│   ├── audit-qa.txt
│   ├── audit-security.txt
│   ├── audit-uiux.txt
│   ├── audit-legal.txt
│   ├── issue-worker.txt
│   ├── pm-staff.txt
│   └── tpm-staff.txt
├── launchd/
│   └── com.minglit.*.plist
└── workers.md            # 이 문서
```
