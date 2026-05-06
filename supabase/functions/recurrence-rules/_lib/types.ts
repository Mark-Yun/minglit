export const VALID_PATTERNS = ["weekly", "biweekly", "monthly"] as const;
export type Pattern = typeof VALID_PATTERNS[number];

export interface RecurrenceRule {
  id: string;
  party_id: string;
  pattern: Pattern;
  days_of_week: number[];
  month_day: number | null;
  start_time: string;
  end_time: string;
  end_date: string | null;
  status: string;
  last_generated_date: string | null;
  created_at: string;
}
