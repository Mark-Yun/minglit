# [UI/UX] 디자인 품질 및 사용성 감사 보고서 (Design & Usability Audit)

**감사 일자:** {{date}} | **대상:** [기능/페이지명]
**담당 디자이너:** {{author}}
**핵심 가치:** #HeuristicEvaluation #Accessibility #MinglitKit_Standards #DarkMode

---

## 1. 개요 및 비즈니스 임팩트 (Executive Summary)
*디자인은 비즈니스 문제를 해결하는 도구입니다. 전체적인 사용성 건강도를 진단하고 가장 시급한 Top 3 과제를 제시합니다.*

- **전반적 건강도 진단:** [우수 / 양호 / 개선필요 / 심각]
- **예상 비즈니스 임팩트:** (예: "결제 이탈 구간의 인지 부하를 줄임으로써 매출 X% 상승 기대")
- **Top 3 시급 과제:**
  1. ...
  2. ...
  3. ...

---

## 2. 10대 휴리스틱 분석 (Heuristic Evaluation)
*Jakob Nielsen의 10가지 사용성 원칙을 기준으로 분석합니다. **위반이 발견된 원칙만** 기술하되, 위반 없는 원칙은 "위반 없음"으로 명시하여 10개 전부 커버합니다. Minglit의 신뢰 구축 여정 {로그인 → 본인인증 → 자격심사 → 티켓선택}에서 발생하는 마찰을 집중 분석합니다.*

| # | 원칙 | 심각도(0-4) | 요약 |
|---|------|:-----------:|------|
| H1 | 시스템 상태의 가시성 | | |
| H2 | 실세계와 시스템의 일치 | | |
| H3 | 사용자 제어와 자유 | | |
| H4 | 일관성과 표준 | | |
| H5 | 오류 예방 | | |
| H6 | 재인지보다 인지 | | |
| H7 | 유연성과 효율성 | | |
| H8 | 미학적이고 최소한 디자인 | | |
| H9 | 오류 인식/진단/복구 | | |
| H10 | 도움말과 문서화 | | |

### 상세 (심각도 2 이상만)

- **위반된 원칙:** (예: H1 시스템 상태의 가시성)
- **심각도 (Severity 0-4):**
- **심층 분석:**
- **해결 제안 (Remediation):**

---

## 3. 프론티어 벤치마크 (Frontier Benchmark)
*Minglit의 UX를 동종/이종 최상위 서비스와 비교합니다. "잘 구현했나?"를 넘어 "시장 최고 수준 대비 어디에 있나?"를 평가합니다.*

### 3.1 벤치마크 대상
*감사 대상 화면/플로우와 유사한 기능을 제공하는 프론티어 서비스를 선정합니다.*

| 비교 영역 | Minglit | 벤치마크 서비스 | 격차 |
|---|---|---|---|
| (예: 이벤트 카드) | 게이지만 표시 | Eventbrite: 뱃지+CTA 분리 | 만석 상태 피드백 부재 |
| (예: 온보딩 플로우) | 체크리스트 4단계 | Airbnb: 프로그레스+스킵 가능 | 스킵 불가, 이탈 위험 |
| (예: Empty State) | 아이콘+텍스트 1줄 | Notion: 일러스트+CTA+가이드 | CTA/가이드 부재 |

### 3.2 채택 권장 패턴
*벤치마크에서 발견한 우수 패턴 중 Minglit에 도입할 만한 것을 구체적으로 제안합니다.*

- **패턴명:** (예: Progressive Disclosure 온보딩)
- **출처 서비스:** (예: Duolingo)
- **Minglit 적용 방안:**
- **예상 효과:**

---

## 4. 컴포넌트별 평가 (Component Scorecard)
*감사 대상 화면/컴포넌트별로 점수를 매깁니다. 골든 이미지(`apps/*/test/goldens/`, `shared/packages/minglit_kit/test/goldens/`)를 참조하여 시각적으로 검증합니다.*

| 컴포넌트 | 평점(1-5) | 비고 |
|----------|:---------:|------|
| (예: EventCard) | | |
| (예: Settlement Empty State) | | |

---

## 5. 디자인 토큰 준수 (Token Compliance)
*`minglit_kit`의 토큰 사용 일관성을 점검합니다.*

- **토큰 준수율:** `MinglitSpacing`, `MinglitRadius`, `MinglitOpacity`, `Theme.textTheme` 사용 여부. 하드코딩된 값 검출.
- **접근성(WCAG AA):** 색상 대비(최소 4.5:1), 포커스 순서, 스크린 리더 대응력.
- **Empty State 패턴:** 빈 상태에 아이콘 + 제목 + 설명 + CTA 구조가 적용되어 있는가?

---

## 6. 위젯 트리 / Layout Dump 분석
*버그 리포트에 첨부된 layout dump 또는 `dumpRenderTree`/`dumpSemanticsTree` 출력을 분석하여 구조적 UX 이슈를 진단합니다. 골든 이미지는 시각적 결과만 보여주지만, 위젯 트리는 **왜** 그렇게 보이는지를 알려줍니다.*

- **위젯 깊이(depth):** 불필요한 중첩이 인지 부하나 성능에 영향을 주는가?
- **Overflow / Constraint 이슈:** `RenderFlex overflowed`, `unbounded constraints` 등 레이아웃 경고가 있는가?
- **Semantics 트리:** 스크린 리더가 읽는 순서와 시각적 순서가 일치하는가? 중요한 요소에 `Semantics` 라벨이 있는가?
- **불필요한 리빌드:** 동일 위젯이 반복 생성되거나, `const` 가능한 위젯이 매번 새로 생성되는가?

> 참조: 버그 리포트의 layout dump URL 또는 `bug-report-attachments/layout-dumps/` 경로

---

## 7. Dark Mode 검증
*Light/Dark 양쪽 골든 이미지를 비교하여 다크 모드 품질을 평가합니다.*

- **Surface 대비:** 배경-텍스트 간 WCAG AA 충족 여부
- **컬러 매핑:** Light에서 사용된 브랜드 컬러가 Dark에서 적절히 변환되었는가?
- **이슈 목록:** (예: skeleton loader 대비 부족, 뱃지 텍스트 가독성 미달)

---

## 8. 인지 부하 및 힉의 법칙 분석 (Cognitive Load & Hick's Law)
*화면 내 정보 밀도가 사용자의 의사결정을 방해하고 있지 않은지, 불필요한 시각적 노이즈가 핵심 CTA를 가리고 있지 않은지 분석합니다.*

---

## 9. 개선 로드맵 (The Roadmap)
- **Quick Wins (저비용 고효율):** 즉각적인 지표 상승을 가져올 수정 사항.
- **Deep UX Redesign:** 구조적인 설계 변경이 필요한 장기 과제.

---

## 10. 참고
1. **Jakob Nielsen (NN/g):** "10 Usability Heuristics for User Interface Design".
2. **W3C:** "Web Content Accessibility Guidelines (WCAG) 2.1".
3. **Minglit UX Docs:** `docs/ux/design-system/`
4. **골든 이미지:** `apps/app_user/test/goldens/`, `apps/app_partner/test/goldens/`, `shared/packages/minglit_kit/test/goldens/`
5. **Layout Dump:** 버그 리포트 첨부 파일 또는 `bug-report-attachments/layout-dumps/`
