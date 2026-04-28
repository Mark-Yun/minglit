/**
 * Client-safe token types + composite text-style data.
 * Pure data — no fs / no Node-only deps. Safe to import from client
 * components. The server-only fetch helpers live in `tokens.ts`.
 */

export interface ColorToken {
  name: string;
  cssVar: string;
  dartName: string;
  hex: string;
  description: string;
  group: 'semantic' | 'dark' | 'partner';
}

export interface SpacingToken {
  name: string;
  cssVar: string;
  value: number;
  description: string;
}

export interface RadiusToken {
  name: string;
  cssVar: string;
  value: number;
  description: string;
}

export interface TypographyToken {
  name: string;
  cssVar: string;
  value: string | number;
  type: 'fontFamily' | 'fontSize' | 'fontWeight' | 'lineHeight';
  description: string;
}

export interface TextStyle {
  /** Suffix of `.mds-text-*` utility class. */
  key: string;
  /** Display name. */
  label: string;
  /** Where / why to use this style — purpose, not size. */
  description: string;
  /** Sample text rendered with the style applied. */
  sample: string;
  /** Primitives this style references (cssVar names). */
  primitives: {
    fontSize?: string;
    fontWeight?: string;
    lineHeight?: string;
    fontFamily?: string;
  };
}

export const TEXT_STYLES: TextStyle[] = [
  {
    key: 'caption-tiny',
    label: 'caption-tiny',
    description: '약관·고지·저작권 같은 법적/보조 텍스트. 본문보다 한 단계 더 작은 라인.',
    sample: '© 2026 Minglit Inc. 모든 권리 보유',
    primitives: { fontSize: '--typography-font-size-caption-tiny', lineHeight: '--typography-line-height-normal' },
  },
  {
    key: 'caption',
    label: 'caption',
    description: '타임스탬프, 위치, 카운트 같은 메타데이터. 본문 옆에 붙는 보조 정보.',
    sample: '5분 전 · 강남구',
    primitives: { fontSize: '--typography-font-size-caption', lineHeight: '--typography-line-height-normal' },
  },
  {
    key: 'chip-label',
    label: 'chip-label',
    description: '칩/태그 안의 짧은 라벨. 카테고리, 필터, 상태 표시.',
    sample: '재즈 · 인디 · 하우스',
    primitives: { fontSize: '--typography-font-size-chip-label', lineHeight: '--typography-line-height-tight' },
  },
  {
    key: 'body',
    label: 'body',
    description: '기본 본문. 이벤트 설명, 게시글, 상세 페이지의 가독 텍스트. 긴 글에는 relaxed line-height.',
    sample: '오늘 저녁 7시, 강남의 한 재즈바에서 작은 모임을 열어요. 처음 오는 분들도 편하게 참여하실 수 있어요.',
    primitives: { fontSize: '--typography-font-size-body', lineHeight: '--typography-line-height-relaxed' },
  },
  {
    key: 'button',
    label: 'button',
    description: '버튼 라벨, 강조된 인라인 액션. body보다 굵고 약간 크게.',
    sample: '참여하기',
    primitives: {
      fontSize: '--typography-font-size-button',
      fontWeight: '--typography-font-weight-bold',
      lineHeight: '--typography-line-height-tight',
    },
  },
  {
    key: 'app-bar-title',
    label: 'app-bar-title',
    description: '상단 앱바 가운데 타이틀. 화면 단위 제목이 아니라 네비게이션 컨텍스트.',
    sample: '내 모임',
    primitives: {
      fontSize: '--typography-font-size-app-bar-title',
      fontWeight: '--typography-font-weight-semi-bold',
      lineHeight: '--typography-line-height-tight',
    },
  },
  {
    key: 'section-title',
    label: 'section-title',
    description: '한 페이지 안에서 섹션을 구분하는 헤더. body 위에 살짝 강한 무게.',
    sample: '이번 주 인기',
    primitives: {
      fontSize: '--typography-font-size-section-title',
      fontWeight: '--typography-font-weight-semi-bold',
      lineHeight: '--typography-line-height-tight',
    },
  },
  {
    key: 'page-title',
    label: 'page-title',
    description: '한 화면당 하나의 메인 타이틀. 스크롤 컨텐츠의 첫 헤더.',
    sample: '이벤트 둘러보기',
    primitives: {
      fontSize: '--typography-font-size-page-title',
      fontWeight: '--typography-font-weight-bold',
      lineHeight: '--typography-line-height-tight',
    },
  },
  {
    key: 'dialog-title',
    label: 'dialog-title',
    description: '다이얼로그/바텀시트 상단 타이틀. 사용자에게 결정을 요구하는 시점의 강조.',
    sample: '참여를 취소할까요?',
    primitives: {
      fontSize: '--typography-font-size-dialog-title',
      fontWeight: '--typography-font-weight-bold',
      lineHeight: '--typography-line-height-tight',
    },
  },
  {
    key: 'display',
    label: 'display',
    description: '온보딩·랜딩의 히어로 카피. 화면 진입 첫 인상에 쓰는 큰 텍스트.',
    sample: '오늘 밤, 어디 갈까?',
    primitives: {
      fontSize: '--typography-font-size-display',
      fontWeight: '--typography-font-weight-bold',
      lineHeight: '--typography-line-height-tight',
    },
  },
  {
    key: 'display-brand',
    label: 'display-brand',
    description: '스플래시의 브랜드 로고 텍스트. Racing Sans One 디스플레이 폰트 전용.',
    sample: 'Minglit',
    primitives: {
      fontFamily: '--typography-font-family-display',
      fontSize: '--typography-font-size-display-brand',
      lineHeight: '--typography-line-height-tight',
    },
  },
];
