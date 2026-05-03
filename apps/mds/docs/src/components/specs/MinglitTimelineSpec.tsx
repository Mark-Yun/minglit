/**
 * MinglitTimeline — vertical stepper showing time-ordered events.
 *
 * Source: TBD — Flutter widget 신규 작성 필요 (이 spec이 design intent).
 *
 * Visual contract:
 *   세로 stepper. 각 step은 좌측 dot + 그 아래로 이어지는 line + 우측 컨텐츠
 *   영역(title + 자유 trailing slot + 자유 children slot). 마지막 step은 line 없음.
 *   Dot 색은 tone에 따라 분기 — success / progress / error / neutral / muted.
 *
 * Tone vs status:
 *   tone은 semantic-neutral (성공/진행/실패/완료/대기). 어떤 도메인의 lifecycle도
 *   매핑 가능. 신청 review에서는 completed→success, active→progress(+pulsing),
 *   failed→error, cancelled→neutral 로 매핑. 다른 use case는 자체 매핑.
 *
 * Pulsing:
 *   tone과 orthogonal한 별도 prop. 보통 "현재 진행 중인 step"을 강조할 때 사용.
 *   tone=progress와 함께 쓰는 게 일반적이지만, 어떤 tone과도 결합 가능.
 *
 * Composability:
 *   step의 trailing slot에 시점 / 금액 / badge / icon 무엇이든. children slot에
 *   사유 박스 / collapsible / CTA 등 page-specific 컨텐츠 주입. 컴포넌트 자체는
 *   structure (dot/line/heading row)만 책임.
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

type Tone = 'success' | 'progress' | 'error' | 'neutral' | 'muted';

const DOT_BG: Record<Tone, string> = {
  success: 'var(--color-success)',
  progress: 'var(--color-primary)',
  error: 'var(--color-error)',
  neutral: 'var(--color-text-secondary)',
  muted: 'transparent',
};

const DOT_BORDER: Record<Tone, string> = {
  success: '2px solid var(--color-background, white)',
  progress: '2px solid var(--color-background, white)',
  error: '2px solid var(--color-background, white)',
  neutral: '2px solid var(--color-background, white)',
  muted: '2px solid var(--color-text-secondary)',
};

const TITLE_COLOR: Record<Tone, string> = {
  success: 'var(--color-text-primary)',
  progress: 'var(--color-primary)',
  error: 'var(--color-error)',
  neutral: 'var(--color-text-primary)',
  muted: 'var(--color-text-secondary)',
};

function TimelineStepDemo({
  tone,
  pulsing = false,
  title,
  trailing,
  isLast = false,
  children,
}: {
  tone: Tone;
  pulsing?: boolean;
  title: string;
  trailing?: ReactNode;
  isLast?: boolean;
  children?: ReactNode;
}) {
  return (
    <div
      style={{
        position: 'relative',
        paddingBottom: isLast ? 0 : 32,
      }}
    >
      {/* connecting line */}
      {!isLast && (
        <span
          style={{
            position: 'absolute',
            left: -23,
            top: 18,
            bottom: -8,
            width: 2,
            background: 'var(--color-divider)',
          }}
        />
      )}
      {/* dot */}
      <span
        style={{
          position: 'absolute',
          left: -28,
          top: 4,
          width: 12,
          height: 12,
          borderRadius: '50%',
          background: DOT_BG[tone],
          border: DOT_BORDER[tone],
          boxSizing: 'border-box',
          animation: pulsing ? 'mds-spec-pulse 1.4s ease-in-out infinite' : undefined,
        }}
      />
      {/* heading row — title + trailing slot */}
      <div style={{ display: 'flex', alignItems: 'baseline', flexWrap: 'wrap', gap: 8 }}>
        <span
          style={{
            fontSize: 14,
            fontWeight: 600,
            color: TITLE_COLOR[tone],
            lineHeight: 1.3,
          }}
        >
          {title}
        </span>
        {trailing && (
          <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>{trailing}</span>
        )}
      </div>
      {children && <div style={{ marginTop: 8, fontSize: 13 }}>{children}</div>}
    </div>
  );
}

function TimelineDemo({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        position: 'relative',
        background: 'white',
        padding: '16px 16px 16px 48px',
        borderRadius: 16,
        border: '1px solid var(--color-divider)',
      }}
    >
      <style>{`
        @keyframes mds-spec-pulse {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.5; transform: scale(0.85); }
        }
      `}</style>
      {children}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitTimelineSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <TimelineDemo>
          <TimelineStepDemo tone="success" title="신청" trailing="2026.04.10 19:42" />
          <TimelineStepDemo tone="success" title="결제 완료" trailing="2026.04.10 19:43 · 25,000원" />
          <TimelineStepDemo tone="progress" pulsing title="심사 진행 중" isLast>
            <span style={{ color: 'var(--color-text-secondary)' }}>
              이벤트 시작까지 자동 환불 안내
            </span>
          </TimelineStepDemo>
        </TimelineDemo>
      </SpecHero>

      <SpecAnatomy
        subject={
          <TimelineDemo>
            <TimelineStepDemo tone="success" title="첫 단계" trailing="시점" />
            <TimelineStepDemo tone="progress" pulsing title="진행 중" isLast />
          </TimelineDemo>
        }
        labels={[
          { text: 'dot 12×12 · tone별 색', style: { top: 18, left: 0 } },
          { text: '연결 line 2px · color-divider', style: { top: '50%', left: 14 } },
          { text: 'heading row · title + trailing slot · gap spacing-small', style: { top: 18, right: 0 } },
          { text: 'step 간격 spacing-xlarge (32px)', style: { bottom: 8, right: 0 } },
        ]}
        minHeight={140}
      />

      <SpecSection title="Tone — semantic-neutral 색 분기">
        <PreviewTable
          rows={[
            {
              name: 'success',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="success" title="완료" trailing="시점" isLast />
                </TimelineDemo>
              ),
              description:
                'color-success (초록). 달성 / 통과 / 도달. 신청 review의 completed, order tracking의 delivered 등.',
            },
            {
              name: 'progress',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="progress" title="진행 중" isLast />
                </TimelineDemo>
              ),
              description:
                'color-primary. 현재 진행 중. pulsing prop과 함께 쓰면 박동 효과 추가.',
            },
            {
              name: 'error',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="error" title="실패" trailing="시점" isLast />
                </TimelineDemo>
              ),
              description:
                'color-error (빨강). 실패 / 거절 / 결제 오류. dot + title 모두 error 색.',
            },
            {
              name: 'neutral',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="neutral" title="종결" trailing="시점" isLast />
                </TimelineDemo>
              ),
              description:
                'color-text-secondary (회색). 종결됐으나 강조 안 함. 사용자/시스템 취소, 묻힘 처리 등.',
            },
            {
              name: 'muted',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="muted" title="대기" isLast />
                </TimelineDemo>
              ),
              description:
                'outline only (filled X · border만). 미래 / 대기 / 아직 도달하지 않은 step. 미래 step도 보여줘야 할 때.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Pulsing — tone과 orthogonal한 박동 효과">
        <PreviewTable
          rows={[
            {
              name: 'pulsing=false (default)',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="progress" title="정적 progress" isLast />
                </TimelineDemo>
              ),
              description: '정적 dot. tone progress라도 pulsing은 별도.',
            },
            {
              name: 'pulsing=true',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="progress" pulsing title="박동 progress" isLast />
                </TimelineDemo>
              ),
              description:
                '1.4s loop · opacity 1↔0.5 + scale 1↔0.85. 보통 "지금 진행 중인 단계"를 강조할 때.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Slots — trailing / child">
        <PreviewTable
          rows={[
            {
              name: 'trailing — 시점',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="success" title="신청" trailing="2026.04.10 19:42" isLast />
                </TimelineDemo>
              ),
              description: '시간 metadata 한 줄. heading row의 title 옆 inline.',
            },
            {
              name: 'trailing — 금액',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="success" title="결제 완료" trailing="2026.04.10 · 25,000원" isLast />
                </TimelineDemo>
              ),
              description: '시점 + 금액 등 자유 형태. consumer가 String 또는 Widget 결정.',
            },
            {
              name: 'child — 안내 텍스트',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="progress" pulsing title="심사 진행 중" isLast>
                    <span style={{ color: 'var(--color-text-secondary)' }}>
                      이벤트 시작까지 자동 환불 안내
                    </span>
                  </TimelineStepDemo>
                </TimelineDemo>
              ),
              description: 'step heading 아래 보조 텍스트. 진행 중 안내 / 메모 등.',
            },
            {
              name: 'child — message box',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo
                    tone="error"
                    title="거절됨"
                    trailing="2026.04.13"
                    isLast
                  >
                    <div
                      style={{
                        marginTop: 8,
                        padding: '12px 16px',
                        background: 'rgba(31, 41, 55, 0.04)',
                        borderRadius: 12,
                      }}
                    >
                      <span
                        style={{
                          fontSize: 12,
                          fontWeight: 700,
                          color: 'var(--color-text-secondary)',
                          display: 'block',
                          marginBottom: 4,
                        }}
                      >
                        서울 숲 파티 운영팀
                      </span>
                      사진이 흐려 본인 확인이 어렵습니다.
                    </div>
                  </TimelineStepDemo>
                </TimelineDemo>
              ),
              description:
                'page-specific 사유/메시지 컨테이너를 child slot으로 주입. 컴포넌트는 구조만, 안 컨텐츠는 작성 측 자유.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Last step — line 유무">
        <PreviewTable
          rows={[
            {
              name: 'isLast=false',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="success" title="중간" trailing="시점" />
                  <TimelineStepDemo tone="progress" pulsing title="진행 중" isLast />
                </TimelineDemo>
              ),
              description: '중간 step — dot 아래로 연결 line.',
            },
            {
              name: 'isLast=true',
              preview: (
                <TimelineDemo>
                  <TimelineStepDemo tone="success" title="끝" trailing="시점" isLast />
                </TimelineDemo>
              ),
              description: '마지막 step — line 미렌더.',
            },
          ]}
        />
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// Recipes — semantic use case 매핑 예시
// ---------------------------------------------------------------------------
function ApplicationReviewRecipe() {
  // 신청 review use case: completed→success, active→progress+pulsing
  return (
    <TimelineDemo>
      <TimelineStepDemo tone="success" title="신청" trailing="2026.04.10 19:42" />
      <TimelineStepDemo
        tone="success"
        title="결제 완료"
        trailing="2026.04.10 19:43 · 25,000원"
      />
      <TimelineStepDemo tone="progress" pulsing title="심사 진행 중" isLast>
        <span style={{ color: 'var(--color-text-secondary)' }}>
          이벤트 시작까지 자동 환불 안내
        </span>
      </TimelineStepDemo>
    </TimelineDemo>
  );
}

function OrderTrackingRecipe() {
  // Order tracking use case: delivered→success, shipping→progress, pending→muted
  return (
    <TimelineDemo>
      <TimelineStepDemo tone="success" title="주문 접수" trailing="2026.04.10" />
      <TimelineStepDemo tone="success" title="결제 완료" trailing="2026.04.10" />
      <TimelineStepDemo tone="progress" pulsing title="배송 중" trailing="2026.04.11" />
      <TimelineStepDemo tone="muted" title="배송 완료" isLast />
    </TimelineDemo>
  );
}

function RejectionRecipe() {
  return (
    <TimelineDemo>
      <TimelineStepDemo tone="success" title="신청" trailing="2026.04.10" />
      <TimelineStepDemo tone="success" title="결제 완료" trailing="2026.04.10" />
      <TimelineStepDemo tone="success" title="심사 진행" trailing="2026.04.11" />
      <TimelineStepDemo tone="error" title="거절됨" trailing="2026.04.13" isLast>
        <div
          style={{
            marginTop: 8,
            padding: '12px 16px',
            background: 'rgba(31, 41, 55, 0.04)',
            borderRadius: 12,
          }}
        >
          <span
            style={{
              fontSize: 12,
              fontWeight: 700,
              color: 'var(--color-text-secondary)',
              display: 'block',
              marginBottom: 4,
            }}
          >
            서울 숲 파티 운영팀
          </span>
          제출하신 프로필 사진이 흐려 본인 확인이 어렵습니다.
        </div>
      </TimelineStepDemo>
    </TimelineDemo>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'application-review': ApplicationReviewRecipe,
  'order-tracking': OrderTrackingRecipe,
  'rejection-flow': RejectionRecipe,
};
