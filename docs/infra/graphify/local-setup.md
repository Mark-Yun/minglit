# 로컬 환경 — 옛 hook 제거

GitHub Actions 워크플로우가 `graphify-out/` 을 자동 갱신하므로, 로컬에 설치된 `post-commit` hook 은 더 이상 필요하지 않다. 오히려 다음 문제를 일으킨다.

- 매 커밋마다 1270 파일 AST 추출 (수십초 지연)
- `graphify-out/` 이 매번 dirty 로 남음 → `git pull` abort, working tree 오염
- 노드 수 5000+ 에서 viz rebuild 실패가 매번 발생

## 제거 방법

### 방법 1: graphify CLI

```bash
graphify hook uninstall
```

`graphify hook install` 로 설치했다면 동일 도구로 제거 가능하다.

### 방법 2: 수동 삭제

```bash
rm .git/hooks/post-commit
rm .git/hooks/post-checkout   # graphify 가 같이 설치한 경우
```

`.git/hooks/` 는 로컬 디렉토리이므로 안전하게 삭제 가능하다 (커밋 대상 아님).

### 확인

```bash
ls .git/hooks/ | grep -v sample
```

비어있거나 graphify 와 무관한 hook 만 남으면 완료.

## 그래도 로컬에서 graph 를 보고 싶다면

이슈 진단 등으로 즉시 최신 graph 가 필요하면 수동으로 실행한다.

```bash
graphify update . --no-viz
```

이후 커밋하지 말고 (워크플로우가 dev 에서 갱신하므로) 변경분은 버린다.

```bash
git checkout HEAD -- graphify-out/
git clean -fd graphify-out/
```
