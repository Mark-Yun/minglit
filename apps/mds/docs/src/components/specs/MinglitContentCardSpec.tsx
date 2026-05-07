/**
 * MinglitContentCard — unified card container.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_content_card.dart
 *   highlighted: true면 primary 색 보더로 강조
 *   onTap: 있으면 잉크 리플 + 탭 가능
 *   padding: 기본은 vertical cardContentV / horizontal medium
 *
 * Visual contract:
 *   둥근 모서리 카드 (radius-card 16) · 내부 padding · 회색 1px 보더.
 *   highlighted=true면 보더가 primary 색으로 변경 (강조 카드).
 *   탭 가능한 카드는 화면 전체 둥근 모서리 안쪽으로 잉크 리플 효과.
 */

import type { ComponentType, ReactNode } from 'react';
import {
  PreviewTable,
  SpecAnatomy,
  SpecHero,
  SpecRoot,
  SpecSection,
} from './_atoms';

// ---------------------------------------------------------------------------
// Atom
// ---------------------------------------------------------------------------
function ContentCardDemo({
  children,
  highlighted = false,
  tappable = false,
  bordered = true,
  width,
}: {
  children: ReactNode;
  highlighted?: boolean;
  tappable?: boolean;
  bordered?: boolean;
  width?: number | string;
}) {
  // highlighted 우선 (선택 강조). bordered=false일 때 보더 자체 제거.
  const border = highlighted
    ? '1px solid var(--color-primary)'
    : bordered
      ? '1px solid var(--color-divider)'
      : 'none';
  return (
    <div
      style={{
        width,
        padding: '16px 16px',
        background: 'white',
        borderRadius: 16,
        border,
        cursor: tappable ? 'pointer' : 'default',
        transition: 'box-shadow 0.15s',
      }}
    >
      {children}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitContentCardSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <ContentCardDemo width={320}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <span style={{ fontSize: 16, fontWeight: 600, color: 'var(--color-text-primary)' }}>
              루프탑 라운지
            </span>
            <span style={{ fontSize: 14, color: 'var(--color-text-secondary)' }}>
              강남 · 5월 3일 토 · 19:00
            </span>
          </div>
        </ContentCardDemo>
      </SpecHero>

      <SpecAnatomy
        subject={
          <ContentCardDemo width={320}>
            <span style={{ fontSize: 14, color: 'var(--color-text-primary)' }}>카드 콘텐츠 영역</span>
          </ContentCardDemo>
        }
        labels={[
          { text: 'radius-card (16) · 둥근 모서리', style: { top: 4, left: '50%', transform: 'translateX(-50%)' } },
          { text: 'cardContentV → 위아래 padding', style: { top: '50%', left: 0 } },
          { text: 'spacing-medium → 좌우 padding (16)', style: { top: '50%', right: 0 } },
          { text: '1px outlineVariant border (회색)', style: { bottom: 4, left: '50%', transform: 'translateX(-50%)' } },
        ]}
      />

      <SpecSection title="Variants">
        <PreviewTable
          rows={[
            {
              name: 'default',
              preview: (
                <ContentCardDemo width={240}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <span style={{ fontSize: 14, fontWeight: 600 }}>일반 카드</span>
                    <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>회색 보더</span>
                  </div>
                </ContentCardDemo>
              ),
              description: '회색 보더의 일반 카드. 정보 / 콘텐츠 컨테이너로 사용.',
            },
            {
              name: 'highlighted',
              preview: (
                <ContentCardDemo width={240} highlighted>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <span style={{ fontSize: 14, fontWeight: 600 }}>강조 카드</span>
                    <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>보라 보더</span>
                  </div>
                </ContentCardDemo>
              ),
              description: '보더가 primary 색으로 변경 — 선택됨 / 추천 / 활성 상태를 시각적으로 표시.',
            },
            {
              name: 'tappable',
              preview: (
                <ContentCardDemo width={240} tappable>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <span style={{ fontSize: 14, fontWeight: 600 }}>탭 가능 카드</span>
                    <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>탭 → 다음 화면</span>
                  </div>
                </ContentCardDemo>
              ),
              description: 'onTap이 연결된 카드. 탭 시 카드 내부에 잉크 리플 효과가 둥근 모서리 안쪽까지 표시.',
            },
            {
              name: 'borderless (bordered=false)',
              preview: (
                <div style={{ background: 'var(--color-surface)', padding: 12, borderRadius: 12 }}>
                  <ContentCardDemo width={216} bordered={false}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                      <span style={{ fontSize: 14, fontWeight: 600 }}>보더 없는 카드</span>
                      <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>bg 대비로만 분리</span>
                    </div>
                  </ContentCardDemo>
                </div>
              ),
              description:
                '보더 제거 — 페이지 내 카드가 다수 쌓이고 섹션 헤더 + bg 대비로 위계가 충분히 명확할 때. 운영 hub 화면에서 정보 도메인이 같은 카드들을 가볍게 묶을 때 사용. 기본값(true) 유지가 일반적.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Composition">
        <PreviewTable
          rows={[
            {
              name: 'simple text',
              preview: (
                <ContentCardDemo width={240}>
                  <span style={{ fontSize: 14, color: 'var(--color-text-primary)' }}>안내 메시지가 들어갈 자리.</span>
                </ContentCardDemo>
              ),
              description: '단순 텍스트만 — 안내문 / 알림 / 빈 상태 메시지.',
            },
            {
              name: 'title + body',
              preview: (
                <ContentCardDemo width={240}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    <span style={{ fontSize: 16, fontWeight: 600 }}>제목</span>
                    <span style={{ fontSize: 14, color: 'var(--color-text-secondary)' }}>본문 내용 한두 줄.</span>
                  </div>
                </ContentCardDemo>
              ),
              description: '가장 흔한 패턴 — 제목 + 짧은 설명.',
            },
            {
              name: 'rich content',
              preview: (
                <ContentCardDemo width={240}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    <span style={{ fontSize: 16, fontWeight: 600 }}>카드 제목</span>
                    <div style={{ height: 80, background: 'var(--color-surface)', borderRadius: 8 }} />
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>2026.05.03</span>
                      <span style={{ fontSize: 12, color: 'var(--color-primary)' }}>자세히 →</span>
                    </div>
                  </div>
                </ContentCardDemo>
              ),
              description: '복잡한 콘텐츠도 자유 구성 — 이미지 / 메타 / 액션 텍스트 등.',
            },
          ]}
        />
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// Recipes
// ---------------------------------------------------------------------------
function DoHighlightSelected() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <ContentCardDemo width={220}><span style={{ fontSize: 13 }}>옵션 A</span></ContentCardDemo>
      <ContentCardDemo width={220} highlighted><span style={{ fontSize: 13, fontWeight: 600 }}>옵션 B (선택됨)</span></ContentCardDemo>
      <ContentCardDemo width={220}><span style={{ fontSize: 13 }}>옵션 C</span></ContentCardDemo>
    </div>
  );
}

function DontStackedHighlights() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <ContentCardDemo width={220} highlighted><span style={{ fontSize: 13 }}>옵션 A</span></ContentCardDemo>
      <ContentCardDemo width={220} highlighted><span style={{ fontSize: 13 }}>옵션 B</span></ContentCardDemo>
      <ContentCardDemo width={220} highlighted><span style={{ fontSize: 13 }}>옵션 C</span></ContentCardDemo>
    </div>
  );
}

function DoBorderlessWhenHierarchyClear() {
  // 운영 hub 패턴: 같은 정보 도메인 카드들을 섹션 헤더 + bg 대비로 묶음
  return (
    <div style={{ background: 'var(--color-background)', padding: 12, borderRadius: 12 }}>
      <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: 8 }}>
        참가 현황
      </div>
      <ContentCardDemo width={200} bordered={false}>
        <span style={{ fontSize: 13 }}>전체 분수 + 진행 바</span>
      </ContentCardDemo>
      <div style={{ height: 8 }} />
      <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: 8 }}>
        기대 매출
      </div>
      <ContentCardDemo width={200} bordered={false}>
        <span style={{ fontSize: 13 }}>현재 / 최대 매출</span>
      </ContentCardDemo>
    </div>
  );
}

function DontMixBorderless() {
  // 보더 있는 카드와 없는 카드 섞임 — 카드 경계 인식 어려움
  return (
    <div style={{ background: 'var(--color-background)', padding: 12, borderRadius: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
      <ContentCardDemo width={220}>
        <span style={{ fontSize: 13 }}>이벤트 카드 (bordered)</span>
      </ContentCardDemo>
      <ContentCardDemo width={220} bordered={false}>
        <span style={{ fontSize: 13 }}>알림 메시지 (borderless)</span>
      </ContentCardDemo>
      <ContentCardDemo width={220}>
        <span style={{ fontSize: 13 }}>옵션 카드 (bordered)</span>
      </ContentCardDemo>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-highlight-selected': DoHighlightSelected,
  'dont-stacked-highlights': DontStackedHighlights,
  'do-borderless-when-hierarchy-clear': DoBorderlessWhenHierarchyClear,
  'dont-mix-borderless': DontMixBorderless,
};
