/**
 * MinglitConfirmationPage — 액션 완료 후 노출되는 풀 화면 success 페이지.
 *
 * Toss 디자인 시스템의 "Confirmation Page" 패턴 차용. 결제 / 신청 / 매칭 / 전송 등
 * 사용자 액션이 성공적으로 끝났을 때 culmination 시각으로 노출.
 *
 * Visual contract:
 *   풀 화면 centered layout — 큰 원형 icon(96px · tone fill) + 흰색 stroke check
 *   + bold title + subtle description + 바텀 CTA. AppBar 미렌더(focus 강조).
 *
 * Animation sequence (~1.5s culmination):
 *   1) circle scale-bounce 450ms · cubic-bezier(0.34, 1.56, 0.64, 1)
 *   2) check stroke draw 520ms · stroke-dasharray 트릭 · 320ms delay (손글씨 효과)
 *   3) title fade-up 360ms · 880ms delay
 *   4) description fade-up 360ms · 980ms delay
 *   5) CTA fade-up 360ms · 1120ms delay
 *
 * Tone:
 *   success(초록 · default) · primary(보라 · brand action) · info(파랑) · warning(주황)
 */

import type { ComponentType } from 'react';
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

type Tone = 'success' | 'primary' | 'info' | 'warning';

const TONE_BG: Record<Tone, string> = {
  success: 'var(--color-success)',
  primary: 'var(--color-primary)',
  info: 'var(--color-info)',
  warning: 'var(--color-warning)',
};

function ConfirmCheckIcon() {
  return (
    <svg viewBox="0 0 24 24" width="52" height="52" fill="none">
      <polyline
        points="4 12 9 17 20 6"
        stroke="white"
        strokeWidth="4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function ConfirmInfoIcon() {
  return (
    <svg viewBox="0 0 24 24" width="48" height="48" fill="none">
      <circle cx="12" cy="12" r="10" stroke="white" strokeWidth="3" />
      <line x1="12" y1="11" x2="12" y2="17" stroke="white" strokeWidth="3" strokeLinecap="round" />
      <circle cx="12" cy="7.5" r="1.5" fill="white" />
    </svg>
  );
}

function ConfirmWarningIcon() {
  return (
    <svg viewBox="0 0 24 24" width="48" height="48" fill="none">
      <line x1="12" y1="6" x2="12" y2="13" stroke="white" strokeWidth="3" strokeLinecap="round" />
      <circle cx="12" cy="17.5" r="1.5" fill="white" />
    </svg>
  );
}

function ConfirmHeartIcon() {
  return (
    <svg viewBox="0 0 24 24" width="48" height="48" fill="white">
      <path d="M12 21s-7-4.35-7-10a4.5 4.5 0 0 1 8-3 4.5 4.5 0 0 1 8 3c0 5.65-7 10-7 10z" />
    </svg>
  );
}

function ConfirmationPageDemo({
  tone = 'success',
  title,
  description,
  ctaLabel = '확인',
  iconKind = 'check',
  height = 480,
}: {
  tone?: Tone;
  title: string;
  description?: string;
  ctaLabel?: string;
  iconKind?: 'check' | 'info' | 'warning' | 'heart';
  height?: number;
}) {
  const Icon =
    iconKind === 'info'
      ? ConfirmInfoIcon
      : iconKind === 'warning'
        ? ConfirmWarningIcon
        : iconKind === 'heart'
          ? ConfirmHeartIcon
          : ConfirmCheckIcon;
  return (
    <div
      style={{
        width: 280,
        height,
        background: 'var(--color-background)',
        borderRadius: 16,
        border: '1px solid var(--color-divider)',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      <div
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '0 24px',
          textAlign: 'center',
          gap: 16,
        }}
      >
        <div
          style={{
            width: 96,
            height: 96,
            borderRadius: '50%',
            background: TONE_BG[tone],
            display: 'grid',
            placeItems: 'center',
            color: 'white',
            marginBottom: 4,
          }}
        >
          <Icon />
        </div>
        <div style={{ fontSize: 22, fontWeight: 700, color: 'var(--color-text-primary)' }}>
          {title}
        </div>
        {description && (
          <div
            style={{
              fontSize: 14,
              lineHeight: 1.6,
              color: 'var(--color-text-secondary)',
              maxWidth: 240,
            }}
          >
            {description}
          </div>
        )}
      </div>
      <div
        style={{
          padding: '12px 16px',
          background: 'var(--color-background)',
        }}
      >
        <button
          style={{
            width: '100%',
            height: 56,
            borderRadius: 12,
            border: 'none',
            background: 'var(--color-primary)',
            color: 'white',
            fontSize: 16,
            fontWeight: 700,
            cursor: 'pointer',
          }}
        >
          {ctaLabel}
        </button>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitConfirmationPageSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <ConfirmationPageDemo
          tone="success"
          title="좋아요를 보냈어요"
          description="매칭 결과는 매칭이 모두 종료된 후 알려드릴게요"
        />
      </SpecHero>

      <SpecAnatomy
        subject={
          <ConfirmationPageDemo
            tone="success"
            title="완료됐어요"
            description="잠시 후 다시 확인해주세요"
            height={420}
          />
        }
        labels={[
          { text: 'Icon circle 96px (tone fill)', style: { top: '22%', left: '50%', transform: 'translateX(-50%)' } },
          { text: 'Check stroke 4 · linecap round · 손글씨 draw', style: { top: '32%', right: -8 } },
          { text: 'Title 22/700', style: { top: '52%', left: '50%', transform: 'translateX(-50%)' } },
          { text: 'Description 14/secondary · 2 lines max', style: { top: '62%', left: -8 } },
          { text: 'MinglitBottomCta single (확인)', style: { bottom: 24, left: '50%', transform: 'translateX(-50%)' } },
        ]}
      />

      <SpecSection title="Tone variants">
        <PreviewTable
          rows={[
            {
              name: 'success (default)',
              preview: (
                <ConfirmationPageDemo
                  tone="success"
                  title="결제가 완료됐어요"
                  description="이벤트 입장 QR이 발급됐어요"
                  iconKind="check"
                />
              ),
              description:
                '초록 (color-success #16a34a) · 가장 흔한 성공 culmination — 결제 / 매칭 / 신청 / 전송 등.',
            },
            {
              name: 'primary',
              preview: (
                <ConfirmationPageDemo
                  tone="primary"
                  title="좋아요를 보냈어요"
                  description="서로 좋아요를 보낸 경우 결과 화면에서 알려드릴게요"
                  iconKind="heart"
                />
              ),
              description:
                'brand 보라 (color-primary #9900ff) · brand 액션 강조 시 — 좋아요 / 연결 / 등록 등 brand-distinctive 액션.',
            },
            {
              name: 'info',
              preview: (
                <ConfirmationPageDemo
                  tone="info"
                  title="확인이 필요해요"
                  description="이메일로 발송된 링크를 확인해주세요"
                  iconKind="info"
                />
              ),
              description:
                '파랑 (color-info #3b82f6) · 정보 안내 톤 — 액션 후 추가 단계가 필요하거나 정보성 알림.',
            },
            {
              name: 'warning',
              preview: (
                <ConfirmationPageDemo
                  tone="warning"
                  title="확인할 사항이 있어요"
                  description="일부 항목이 누락됐을 수 있어요"
                  iconKind="warning"
                />
              ),
              description:
                '주황 (color-warning #d97706) · 부분 성공 / 주의 톤 — drop-out 가능 액션 또는 후속 확인 필요.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Composition">
        <PreviewTable
          rows={[
            {
              name: 'with description',
              preview: (
                <ConfirmationPageDemo
                  tone="success"
                  title="신청이 완료됐어요"
                  description="이벤트 시작 1시간 전 알림이 도착해요"
                />
              ),
              description: '가장 일반적 — title + 1-2줄 description + CTA.',
            },
            {
              name: 'title only',
              preview: (
                <ConfirmationPageDemo
                  tone="success"
                  title="저장됐어요"
                />
              ),
              description: '간단한 culmination에 description 생략 가능 — title + CTA만.',
            },
            {
              name: 'with custom CTA label',
              preview: (
                <ConfirmationPageDemo
                  tone="primary"
                  title="회원가입이 완료됐어요"
                  description="이제 이벤트를 둘러볼 수 있어요"
                  ctaLabel="이벤트 둘러보기"
                  iconKind="heart"
                />
              ),
              description:
                'CTA를 forward action으로 — "확인" 대신 다음 단계 안내. onPressed는 해당 route로 push.',
            },
            {
              name: 'auto-dismiss (transient)',
              preview: (
                <div style={{ position: 'relative' }}>
                  <ConfirmationPageDemo
                    tone="success"
                    title="복사됐어요"
                    height={360}
                    ctaLabel="확인"
                  />
                  <div
                    style={{
                      position: 'absolute',
                      top: 8,
                      right: 8,
                      background: 'var(--color-text-primary)',
                      color: 'var(--color-background)',
                      padding: '4px 8px',
                      borderRadius: 4,
                      fontSize: 11,
                    }}
                  >
                    autoDismiss: 1.5s
                  </div>
                </div>
              ),
              description:
                'autoDismiss prop 지정 시 일정 시간 후 자동 pop — 짧은 confirmation에 적합. CTA는 그대로 노출 (사용자가 빨리 닫고 싶을 때).',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Animation sequence">
        <div
          style={{
            background: 'var(--color-surface)',
            borderRadius: 12,
            padding: 16,
            fontSize: 13,
            lineHeight: 1.7,
            color: 'var(--color-text-primary)',
          }}
        >
          <strong>~1.5초 culmination sequence</strong>
          <ol style={{ marginTop: 12, paddingLeft: 20, color: 'var(--color-text-secondary)' }}>
            <li>
              <strong>circle scale-bounce</strong> 0-450ms · cubic-bezier(0.34, 1.56, 0.64, 1) ·
              scale 0 → 1.08 → 1
            </li>
            <li>
              <strong>check stroke draw</strong> 320-840ms · cubic-bezier(0.65, 0, 0.45, 1) ·
              stroke-dashoffset 50 → 0 (손글씨 효과)
            </li>
            <li>
              <strong>title fade-up</strong> 880-1240ms · ease · 6px slide-up + opacity
            </li>
            <li>
              <strong>description fade-up</strong> 980-1340ms · ease
            </li>
            <li>
              <strong>CTA fade-up</strong> 1120-1480ms · ease
            </li>
          </ol>
        </div>
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// Recipes
// ---------------------------------------------------------------------------
function DoMatchingSubmitted() {
  return (
    <ConfirmationPageDemo
      tone="success"
      title="좋아요를 보냈어요"
      description="매칭 결과는 매칭이 모두 종료된 후 알려드릴게요"
    />
  );
}

function DoBrandActionPrimary() {
  return (
    <ConfirmationPageDemo
      tone="primary"
      title="요청을 보냈어요"
      description="상대방이 수락하면 알려드릴게요"
      iconKind="heart"
    />
  );
}

function DontTooManyLines() {
  return (
    <div style={{ position: 'relative' }}>
      <ConfirmationPageDemo
        tone="success"
        title="신청이 완료됐어요. 잠시 후 알림으로 안내드려요."
        description="이번 신청은 자동 결제로 진행되며, 결제 완료 시 입장 QR이 발급됩니다. 자세한 내용은 이메일을 확인해주세요. 또한 환불은 24시간 이내 가능합니다."
        height={520}
      />
      <div
        style={{
          position: 'absolute',
          top: 8,
          left: 8,
          background: 'var(--color-error)',
          color: 'white',
          padding: '4px 8px',
          borderRadius: 4,
          fontSize: 11,
        }}
      >
        Title / description 너무 김
      </div>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-matching-submitted': DoMatchingSubmitted,
  'do-brand-action-primary': DoBrandActionPrimary,
  'dont-too-many-lines': DontTooManyLines,
};
