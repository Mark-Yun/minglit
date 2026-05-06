/**
 * MinglitSection — title + content body wrapper.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_section.dart
 *   title: 섹션 제목 (titleMedium · bold 기본)
 *   trailing: 우측에 들어갈 위젯 (예: "더보기 >" 텍스트 버튼)
 *   spacing: 제목과 본문 사이 간격 (기본 sm = 12)
 *   padding: 외곽 padding (기본 horizontal screenEdge = 16)
 *
 * Visual contract:
 *   상세 / 리스트 페이지에서 콘텐츠를 의미 있는 그룹으로 묶어주는 atom.
 *   왼쪽에 굵은 제목 + 오른쪽에 선택적 액션 텍스트 + 그 아래 본문.
 *   horizontal padding 16으로 화면 가장자리에서 떨어진다.
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
function SectionDemo({
  title,
  trailing,
  children,
}: {
  title: string;
  trailing?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column' }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: 12,
        }}
      >
        <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--color-text-primary)' }}>
          {title}
        </span>
        {trailing}
      </div>
      <div>{children}</div>
    </div>
  );
}

function MoreLink() {
  return (
    <a
      style={{
        fontSize: 13,
        color: 'var(--color-primary)',
        cursor: 'pointer',
      }}
    >
      더보기 →
    </a>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitSectionSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: 360, padding: '12px 0' }}>
          <SectionDemo title="추천 이벤트">
            <div
              style={{
                height: 80,
                background: 'var(--color-surface)',
                borderRadius: 12,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--color-text-secondary)',
                fontSize: 13,
              }}
            >
              본문 콘텐츠 영역
            </div>
          </SectionDemo>
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 360, padding: '12px 0' }}>
            <SectionDemo title="섹션 제목" trailing={<MoreLink />}>
              <div
                style={{
                  height: 60,
                  background: 'var(--color-surface)',
                  borderRadius: 8,
                  display: 'flex',
                  alignItems: 'center',
                  paddingLeft: 12,
                  color: 'var(--color-text-secondary)',
                  fontSize: 12,
                }}
              >
                본문
              </div>
            </SectionDemo>
          </div>
        }
        labels={[
          { text: 'titleMedium · bold (제목)', style: { top: 12, left: 8 } },
          { text: 'trailing slot (더보기 / 액션 등)', style: { top: 12, right: 8 } },
          { text: 'spacing-sm → 제목 ↔ 본문 (12)', style: { top: '50%', left: 0 } },
          { text: 'spacing-screenEdge → 좌우 padding 16', style: { bottom: 12, right: 8 } },
        ]}
      />

      <SpecSection title="With / without trailing">
        <PreviewTable
          rows={[
            {
              name: 'with trailing',
              preview: (
                <div style={{ width: 280, padding: '8px 0' }}>
                  <SectionDemo title="추천 이벤트" trailing={<MoreLink />}>
                    <div style={{ height: 40, background: 'var(--color-surface)', borderRadius: 6 }} />
                  </SectionDemo>
                </div>
              ),
              description: '제목 우측에 액션 (예: "더보기 →") — 리스트가 잘려 있을 때 전체 보기로 가는 진입점.',
            },
            {
              name: 'without trailing',
              preview: (
                <div style={{ width: 280, padding: '8px 0' }}>
                  <SectionDemo title="이번 주 일정">
                    <div style={{ height: 40, background: 'var(--color-surface)', borderRadius: 6 }} />
                  </SectionDemo>
                </div>
              ),
              description: '제목만 — 더 이상 진입할 곳 없는 단순 섹션 헤더.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Body composition">
        <PreviewTable
          rows={[
            {
              name: 'list body',
              preview: (
                <div style={{ width: 280, padding: '8px 0' }}>
                  <SectionDemo title="멤버">
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                      <div style={{ height: 32, background: 'var(--color-surface)', borderRadius: 6 }} />
                      <div style={{ height: 32, background: 'var(--color-surface)', borderRadius: 6 }} />
                      <div style={{ height: 32, background: 'var(--color-surface)', borderRadius: 6 }} />
                    </div>
                  </SectionDemo>
                </div>
              ),
              description: '본문이 리스트 — 가장 흔한 패턴. 상세 페이지의 멤버 / 댓글 / 일정 등.',
            },
            {
              name: 'horizontal scroll',
              preview: (
                <div style={{ width: 280, padding: '8px 0' }}>
                  <SectionDemo title="추천 이벤트" trailing={<MoreLink />}>
                    <div style={{ display: 'flex', gap: 8, overflowX: 'auto' }}>
                      <div style={{ width: 80, height: 60, background: 'var(--color-surface)', borderRadius: 8, flexShrink: 0 }} />
                      <div style={{ width: 80, height: 60, background: 'var(--color-surface)', borderRadius: 8, flexShrink: 0 }} />
                      <div style={{ width: 80, height: 60, background: 'var(--color-surface)', borderRadius: 8, flexShrink: 0 }} />
                    </div>
                  </SectionDemo>
                </div>
              ),
              description: '본문이 가로 스크롤 — 카드 캐러셀, 추천 칩 등.',
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
function DoTrailingForOverflow() {
  return (
    <div style={{ width: 240, padding: '8px 0' }}>
      <SectionDemo title="추천 이벤트" trailing={<MoreLink />}>
        <div style={{ height: 50, background: 'var(--color-surface)', borderRadius: 8 }} />
      </SectionDemo>
    </div>
  );
}

function DontTrailingWithoutAction() {
  return (
    <div style={{ width: 240, padding: '8px 0' }}>
      <SectionDemo title="앱 정보" trailing={<MoreLink />}>
        <div style={{ height: 50, background: 'var(--color-surface)', borderRadius: 8 }} />
      </SectionDemo>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-trailing-for-overflow': DoTrailingForOverflow,
  'dont-trailing-without-action': DontTrailingWithoutAction,
};
