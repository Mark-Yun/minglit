/**
 * MinglitContentLayout — 섹션 stack 레이아웃.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_content_layout.dart
 *   sections: 표시할 섹션 위젯 리스트 (보통 MinglitSection)
 *   sectionGap: 섹션 사이 간격 (기본 sectionGap = 40)
 *   topPadding · bottomPadding: 첫/마지막 섹션 여백 (기본 large 24 · xlarge 32)
 *   showDividers: true면 섹션 사이에 thin divider + 양옆 halfGap 배치
 *
 * Visual contract:
 *   상세 페이지의 섹션들을 통일된 간격으로 세로 나열.
 *   스크롤은 부모가 관리 — 자체는 Column이라 어떤 스크롤 컨텍스트에도 안전.
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
// Atoms
// ---------------------------------------------------------------------------
function ContentLayoutDemo({
  sections,
  sectionGap = 40,
  topPadding = 24,
  bottomPadding = 32,
  showDividers = false,
}: {
  sections: ReactNode[];
  sectionGap?: number;
  topPadding?: number;
  bottomPadding?: number;
  showDividers?: boolean;
}) {
  if (sections.length === 0) return null;
  const half = sectionGap / 2;

  return (
    <div
      style={{
        paddingTop: topPadding,
        paddingBottom: bottomPadding,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {sections.map((section, i) => (
        <div key={i}>
          {section}
          {i < sections.length - 1 &&
            (showDividers ? (
              <div style={{ display: 'flex', flexDirection: 'column' }}>
                <div style={{ height: half }} />
                <div style={{ height: 1, background: 'var(--color-divider)' }} />
                <div style={{ height: half }} />
              </div>
            ) : (
              <div style={{ height: sectionGap }} />
            ))}
        </div>
      ))}
    </div>
  );
}

function SectionStub({ title }: { title: string }) {
  return (
    <div style={{ padding: '0 16px' }}>
      <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 8 }}>{title}</div>
      <div style={{ height: 40, background: 'var(--color-surface)', borderRadius: 6 }} />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitContentLayoutSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: 360, background: 'white', borderRadius: 12 }}>
          <ContentLayoutDemo
            sections={[
              <SectionStub key="1" title="이벤트 정보" />,
              <SectionStub key="2" title="장소" />,
              <SectionStub key="3" title="후기" />,
            ]}
          />
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 360, background: 'white', borderRadius: 12 }}>
            <ContentLayoutDemo
              sections={[
                <SectionStub key="1" title="섹션 A" />,
                <SectionStub key="2" title="섹션 B" />,
              ]}
            />
          </div>
        }
        labels={[
          { text: 'spacing-large → top padding (24)', style: { top: 4, left: 8 } },
          { text: 'sectionGap → 섹션 사이 (40)', style: { top: '50%', left: 0 } },
          { text: 'spacing-xlarge → bottom padding (32)', style: { bottom: 4, left: 8 } },
        ]}
      />

      <SpecSection title="Variants">
        <PreviewTable
          rows={[
            {
              name: 'default (no dividers)',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8 }}>
                  <ContentLayoutDemo
                    sections={[
                      <SectionStub key="1" title="섹션 A" />,
                      <SectionStub key="2" title="섹션 B" />,
                      <SectionStub key="3" title="섹션 C" />,
                    ]}
                  />
                </div>
              ),
              description: '여백만으로 섹션을 분리 — 가장 일반적. 기본 sectionGap 40으로 충분히 시원한 간격.',
            },
            {
              name: 'with dividers',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8 }}>
                  <ContentLayoutDemo
                    sections={[
                      <SectionStub key="1" title="섹션 A" />,
                      <SectionStub key="2" title="섹션 B" />,
                      <SectionStub key="3" title="섹션 C" />,
                    ]}
                    showDividers
                  />
                </div>
              ),
              description: '섹션 사이에 1px 얇은 선 — 섹션 경계를 명시적으로 보여야 할 때.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Section count">
        <PreviewTable
          rows={[
            {
              name: '2 sections',
              preview: (
                <div style={{ width: 240, background: 'white', borderRadius: 8 }}>
                  <ContentLayoutDemo
                    sections={[
                      <SectionStub key="1" title="개요" />,
                      <SectionStub key="2" title="상세" />,
                    ]}
                  />
                </div>
              ),
              description: '섹션 2개 — 짧은 상세 페이지.',
            },
            {
              name: '5 sections',
              preview: (
                <div style={{ width: 240, background: 'white', borderRadius: 8 }}>
                  <ContentLayoutDemo
                    sections={[
                      <SectionStub key="1" title="개요" />,
                      <SectionStub key="2" title="장소" />,
                      <SectionStub key="3" title="일정" />,
                      <SectionStub key="4" title="멤버" />,
                      <SectionStub key="5" title="후기" />,
                    ]}
                  />
                </div>
              ),
              description: '많은 섹션 — 풀 상세 페이지. sectionGap 40 덕분에 섹션이 많아져도 시각 리듬 유지.',
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
function DoNoDividersDefault() {
  return (
    <div style={{ width: 220, background: 'white', borderRadius: 8 }}>
      <ContentLayoutDemo
        sections={[
          <SectionStub key="1" title="섹션 A" />,
          <SectionStub key="2" title="섹션 B" />,
        ]}
      />
    </div>
  );
}

function DoDividersOnlyWhenNeeded() {
  return (
    <div style={{ width: 220, background: 'white', borderRadius: 8 }}>
      <ContentLayoutDemo
        sections={[
          <SectionStub key="1" title="입력 정보" />,
          <SectionStub key="2" title="확인 정보" />,
        ]}
        showDividers
      />
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-no-dividers-default': DoNoDividersDefault,
  'do-dividers-only-when-needed': DoDividersOnlyWhenNeeded,
};
