/**
 * MinglitKeyValueRow — 라벨-값 한 줄.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_key_value_row.dart
 *   bold: true이면 값 텍스트가 굵게 (강조 — 가격 / 합계 등)
 *   valueColor: 값 색상 오버라이드 (예: 가격 강조 보라, 잔여 빨강)
 *
 * Visual contract:
 *   왼쪽에 회색 라벨, 오른쪽에 값 — 양 끝 정렬.
 *   행 위아래 padding xsmall(4) — 여러 줄을 stack해도 답답하지 않은 간격.
 *   결제 / 정산 / 정보 row 등에서 사용.
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
// Atom
// ---------------------------------------------------------------------------
function KeyValueRowDemo({
  label,
  value,
  bold = false,
  valueColor,
}: {
  label: string;
  value: string;
  bold?: boolean;
  valueColor?: string;
}) {
  return (
    <div
      style={{
        padding: '4px 0',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        gap: 12,
      }}
    >
      <span style={{ fontSize: 14, color: 'var(--color-text-secondary)' }}>{label}</span>
      <span
        style={{
          fontSize: 14,
          fontWeight: bold ? 700 : 400,
          color: valueColor ?? 'var(--color-text-primary)',
        }}
      >
        {value}
      </span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitKeyValueRowSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: 320 }}>
          <KeyValueRowDemo label="결제 금액" value="35,000원" bold />
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 320 }}>
            <KeyValueRowDemo label="결제 금액" value="35,000원" bold />
          </div>
        }
        labels={[
          { text: 'spacing-xsmall → 위아래 padding (4)', style: { top: 4, left: 8 } },
          { text: 'label · 회색 (onSurfaceVariant)', style: { top: '50%', left: 0 } },
          { text: 'value · 양 끝 정렬', style: { top: '50%', right: 0 } },
          { text: 'bold · 강조 (가격 / 합계)', style: { bottom: 4, right: 8 } },
        ]}
      />

      <SpecSection title="Variants">
        <PreviewTable
          rows={[
            {
              name: 'default',
              preview: (
                <div style={{ width: 240 }}>
                  <KeyValueRowDemo label="이름" value="홍길동" />
                </div>
              ),
              description: '일반 정보 row — 라벨은 회색, 값은 일반 굵기.',
            },
            {
              name: 'bold',
              preview: (
                <div style={{ width: 240 }}>
                  <KeyValueRowDemo label="결제 금액" value="35,000원" bold />
                </div>
              ),
              description: '값을 굵게 — 가격 / 총합 / 강조해야 할 숫자에 사용.',
            },
            {
              name: 'colored value',
              preview: (
                <div style={{ width: 240 }}>
                  <KeyValueRowDemo label="잔여 좌석" value="2석" bold valueColor="var(--color-error)" />
                </div>
              ),
              description: '값에 의미 색상 적용 — 부족 / 경고는 빨강, 강조는 보라 등.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="In context">
        <PreviewTable
          rows={[
            {
              name: 'payment summary',
              preview: (
                <div
                  style={{
                    width: 280,
                    background: 'white',
                    borderRadius: 12,
                    border: '1px solid var(--color-divider)',
                    padding: 16,
                  }}
                >
                  <KeyValueRowDemo label="결제 금액" value="35,000원" />
                  <KeyValueRowDemo label="환불 비율" value="80%" />
                  <KeyValueRowDemo label="수수료" value="-5,000원" />
                  <div style={{ height: 1, background: 'var(--color-divider)', margin: '6px 0' }} />
                  <KeyValueRowDemo label="환불 금액" value="30,000원" bold valueColor="var(--color-primary)" />
                </div>
              ),
              description: '결제 / 환불 요약 카드 — 여러 row를 stack하고 마지막에 합계를 강조.',
            },
            {
              name: 'event info',
              preview: (
                <div style={{ width: 280, padding: '0 4px' }}>
                  <KeyValueRowDemo label="장소" value="강남 라운지" />
                  <KeyValueRowDemo label="일시" value="5월 3일 토 19:00" />
                  <KeyValueRowDemo label="정원" value="20명" />
                </div>
              ),
              description: '이벤트 / 파티 메타 정보 — 단순 정보 나열용.',
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
function DoBoldForTotal() {
  return (
    <div
      style={{
        width: 220,
        background: 'white',
        borderRadius: 8,
        border: '1px solid var(--color-divider)',
        padding: 12,
      }}
    >
      <KeyValueRowDemo label="결제 금액" value="35,000원" />
      <KeyValueRowDemo label="수수료" value="-5,000원" />
      <KeyValueRowDemo label="환불 금액" value="30,000원" bold valueColor="var(--color-primary)" />
    </div>
  );
}

function DontEverythingBold() {
  return (
    <div
      style={{
        width: 220,
        background: 'white',
        borderRadius: 8,
        border: '1px solid var(--color-divider)',
        padding: 12,
      }}
    >
      <KeyValueRowDemo label="결제 금액" value="35,000원" bold />
      <KeyValueRowDemo label="수수료" value="-5,000원" bold />
      <KeyValueRowDemo label="환불 금액" value="30,000원" bold />
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-bold-for-total': DoBoldForTotal,
  'dont-everything-bold': DontEverythingBold,
};
