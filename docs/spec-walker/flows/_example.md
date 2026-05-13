# 예시: 유저 이벤트 신청 플로우

> 이 파일은 예시다. 파일명이 `_` 로 시작하면 워커가 무시한다. 실제 flow 는 `_` 없이 작성한다.

## 개요

홈에서 이벤트 카드를 탭하여 신청 완료까지 도달하는 happy path.

## Setup

- 디바이스: app_user dev 빌드 설치
- 시드 사용자: `seed-user-1@minglit.test` 로 로그인
- 사전 상태: 홈 화면에 진행 중인 이벤트가 최소 1개 보임

## Steps

1. **홈 화면 진입**
   - 화면: `HomeRoute`
   - 트리거: 앱 콜드 스타트 후 로그인 완료
   - 스크린샷: yes

2. **이벤트 카드 탭**
   - 화면: `HomeRoute` → `EventDetailRoute`
   - 트리거: 홈의 첫 번째 이벤트 카드 tap
   - 스크린샷: yes

3. **신청 버튼 탭**
   - 화면: `EventDetailRoute` → `EventApplicationRoute`
   - 트리거: 화면 하단 "신청하기" 버튼 tap
   - 스크린샷: yes

4. **신청 폼 입력**
   - 화면: `EventApplicationRoute`
   - 트리거: 필수 입력 필드를 시드 데이터로 채운다
   - 스크린샷: yes
   - 메모: 입력 항목 변경 시 시드 데이터 업데이트 필요

5. **제출**
   - 화면: `EventApplicationRoute` → `EventApplicationSuccessRoute`
   - 트리거: "제출" 버튼 tap
   - 스크린샷: yes

## 검증 포인트

- step 1: 홈의 카드 레이아웃이 깨지지 않았는지
- step 3: 신청 버튼이 화면 하단에 sticky 인지 (스크롤 없이도 보여야 함)
- step 5: 성공 화면의 confetti / illustration 이 렌더링 되는지
