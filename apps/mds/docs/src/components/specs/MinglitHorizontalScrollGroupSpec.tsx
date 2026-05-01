/**
 * MinglitHorizontalScrollGroup — horizontal scroll affordance wrapper.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_horizontal_scroll_group.dart
 *   child: 가로 스크롤 가능한 위젯 (ListView · SingleChildScrollView 등)
 *
 * Visual contract:
 *   가로 스크롤 콘텐츠를 감싸 양 끝에 affordance를 자동 추가:
 *   - 좌측: 우측으로 스크롤된 상태일 때 좌측 페이드 (앞 콘텐츠 있음 신호)
 *   - 우측: 더 보여줄 콘텐츠가 있을 때 우측 페이드 + chevron 인디케이터
 *   끝까지 스크롤하면 해당 쪽 페이드가 자동으로 사라짐.
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
function ChipStub({ label }: { label: string }) {
  return (
    <div
      style={{
        height: 32,
        padding: '0 14px',
        borderRadius: 999,
        background: 'var(--color-surface)',
        border: '1px solid var(--color-divider)',
        display: 'inline-flex',
        alignItems: 'center',
        fontSize: 13,
        color: 'var(--color-text-primary)',
        flexShrink: 0,
      }}
    >
      {label}
    </div>
  );
}

function ChevronRight() {
  return (
    <svg viewBox="0 0 24 24" width={16} height={16} fill="none" stroke="currentColor" strokeWidth={2}>
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}

function ScrollGroupDemo({
  children,
  showLeftFade = false,
  showRightFade = true,
}: {
  children: ReactNode;
  showLeftFade?: boolean;
  showRightFade?: boolean;
}) {
  return (
    <div style={{ position: 'relative', overflow: 'hidden' }}>
      <div
        style={{
          display: 'flex',
          gap: 8,
          padding: '8px 0',
          overflowX: 'auto',
          scrollbarWidth: 'none',
        }}
      >
        {children}
      </div>
      {showLeftFade && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            bottom: 0,
            left: 0,
            width: 16,
            background: 'linear-gradient(to right, var(--color-surface), transparent)',
            pointerEvents: 'none',
          }}
        />
      )}
      {showRightFade && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            bottom: 0,
            right: 0,
            display: 'flex',
            alignItems: 'center',
            pointerEvents: 'none',
          }}
        >
          <div
            style={{
              width: 16,
              height: '100%',
              background: 'linear-gradient(to left, var(--color-surface), transparent)',
            }}
          />
          <div
            style={{
              background: 'var(--color-surface)',
              padding: '0 2px',
              display: 'flex',
              alignItems: 'center',
              color: 'var(--color-text-secondary)',
              opacity: 0.6,
            }}
          >
            <ChevronRight />
          </div>
        </div>
      )}
    </div>
  );
}

function chipsList() {
  return ['전체', '파티', '클래스', '스포츠', '아트', '소셜', '와인', '음악'].map((label, i) => (
    <ChipStub key={i} label={label} />
  ));
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitHorizontalScrollGroupSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: 360, background: 'var(--color-surface)', padding: '8px 16px', borderRadius: 12 }}>
          <ScrollGroupDemo>{chipsList()}</ScrollGroupDemo>
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 360, background: 'var(--color-surface)', padding: '8px 16px', borderRadius: 12 }}>
            <ScrollGroupDemo showLeftFade showRightFade>
              {chipsList()}
            </ScrollGroupDemo>
          </div>
        }
        labels={[
          { text: '좌측 페이드 — 앞에 더 있음 신호', style: { top: '50%', left: 0 } },
          { text: '우측 페이드 + chevron — 뒤에 더 있음', style: { top: '50%', right: 0 } },
          { text: '페이드 너비 = spacing-medium (16)', style: { bottom: 4, right: 8 } },
        ]}
      />

      <SpecSection title="Scroll positions">
        <PreviewTable
          rows={[
            {
              name: 'start (좌측 끝)',
              preview: (
                <div style={{ width: 280, background: 'var(--color-surface)', padding: '8px 12px', borderRadius: 8 }}>
                  <ScrollGroupDemo showLeftFade={false} showRightFade>{chipsList()}</ScrollGroupDemo>
                </div>
              ),
              description: '맨 처음 — 좌측 페이드 없음, 우측 페이드 + chevron으로 더 있다는 신호.',
            },
            {
              name: 'middle (스크롤 중)',
              preview: (
                <div style={{ width: 280, background: 'var(--color-surface)', padding: '8px 12px', borderRadius: 8 }}>
                  <ScrollGroupDemo showLeftFade showRightFade>{chipsList()}</ScrollGroupDemo>
                </div>
              ),
              description: '중간 — 양쪽 모두 페이드. 좌우 모두 더 볼 수 있음을 시각적으로 알림.',
            },
            {
              name: 'end (우측 끝)',
              preview: (
                <div style={{ width: 280, background: 'var(--color-surface)', padding: '8px 12px', borderRadius: 8 }}>
                  <ScrollGroupDemo showLeftFade showRightFade={false}>{chipsList()}</ScrollGroupDemo>
                </div>
              ),
              description: '맨 끝까지 스크롤 — 우측 페이드와 chevron 사라짐. 좌측에 페이드만 남아 앞이 있음을 알림.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Content type">
        <PreviewTable
          rows={[
            {
              name: 'chips row',
              preview: (
                <div style={{ width: 260, background: 'var(--color-surface)', padding: '8px 12px', borderRadius: 8 }}>
                  <ScrollGroupDemo showLeftFade={false} showRightFade>{chipsList()}</ScrollGroupDemo>
                </div>
              ),
              description: '필터 칩 / 카테고리 칩 등 — 가장 흔한 사용처.',
            },
            {
              name: 'card carousel',
              preview: (
                <div style={{ width: 260, background: 'var(--color-surface)', padding: '8px 12px', borderRadius: 8 }}>
                  <ScrollGroupDemo showLeftFade={false} showRightFade>
                    {[1, 2, 3, 4].map((i) => (
                      <div
                        key={i}
                        style={{
                          width: 100,
                          height: 80,
                          background: 'white',
                          border: '1px solid var(--color-divider)',
                          borderRadius: 8,
                          flexShrink: 0,
                        }}
                      />
                    ))}
                  </ScrollGroupDemo>
                </div>
              ),
              description: '카드 캐러셀 — 추천 이벤트, 파트너 미리보기 등.',
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
function DoChipsRow() {
  return (
    <div style={{ width: 220, background: 'var(--color-surface)', padding: '8px 12px', borderRadius: 8 }}>
      <ScrollGroupDemo showLeftFade={false} showRightFade>{chipsList()}</ScrollGroupDemo>
    </div>
  );
}

function DontWrapNonScrollable() {
  return (
    <div style={{ width: 220, background: 'var(--color-surface)', padding: '8px 12px', borderRadius: 8 }}>
      <ScrollGroupDemo showLeftFade={false} showRightFade={false}>
        {[1, 2, 3].map((i) => (
          <ChipStub key={i} label={`항목 ${i}`} />
        ))}
      </ScrollGroupDemo>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-chips-row': DoChipsRow,
  'dont-wrap-non-scrollable': DontWrapNonScrollable,
};
