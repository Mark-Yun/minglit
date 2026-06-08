/**
 * DB 타입 — `supabase gen types typescript` 생성물 자리.
 *
 * TODO(gen:types): 아직 placeholder. `npm run gen:types` 실행 후 이 파일 전체가
 * 생성물로 교체된다 (사용법은 패키지 README.md).
 *
 * 규칙 (docs/architecture/web-client.md §2.1): 생성물 — 수기 수정 금지.
 * 스키마 변경 시 재생성하며, 수기 타입과의 drift 를 만들지 않는다.
 */
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: Record<
      string,
      {
        Row: Record<string, unknown>;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: unknown[];
      }
    >;
    Views: Record<string, { Row: Record<string, unknown> }>;
    Functions: Record<
      string,
      { Args: Record<string, unknown>; Returns: unknown }
    >;
    Enums: Record<string, string>;
    CompositeTypes: Record<string, Record<string, unknown>>;
  };
}
