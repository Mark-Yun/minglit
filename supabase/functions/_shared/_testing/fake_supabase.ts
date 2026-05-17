// _shared/_testing/fake_supabase.ts — chainable fake SupabaseClient
//
// 목적: EF handler unit test 에서 DB 호출을 scripted response 로 재현.
// 핵심: builder chain (`.from().select().eq()...`) 가 **실제로 실행** 되도록 만들어
// Deno coverage 가 EF 의 DB 라인까지 trace 하게 함.
//
// 비기능 (의도적 제외):
//  - RLS 시뮬레이션 (L4 integration 책임)
//  - Realtime / Storage
//  - 호출 순서 strict matching (refactor 내성)

export type ScriptedResponse<T = unknown> = {
  data?: T | null;
  error?: PgError | null;
};

export interface PgError {
  message: string;
  code?: string; // postgres error code (e.g. "23505")
  details?: string;
  hint?: string;
}

export type Op = "select" | "insert" | "update" | "delete" | "upsert" | "rpc";

export interface QueryState {
  table: string;
  op: Op;
  filters: Array<{ kind: string; col?: string; val?: unknown }>;
  payload?: unknown;
  rpcArgs?: Record<string, unknown>;
  selectCols?: string;
  isSingle?: boolean;
  isMaybeSingle?: boolean;
  limit?: number;
  order?: { col: string; ascending?: boolean };
}

export interface Script {
  table: string;
  op: Op;
  /** Optional matcher — given the query state, return true if this script applies. */
  match?: (state: QueryState) => boolean;
  returns: ScriptedResponse;
  consumed?: boolean;
}

export interface FakeSupabaseOptions {
  /** Throw if a query has no matching script (default true). false → returns { data: null, error: null }. */
  strict?: boolean;
}

export class FakeSupabase {
  private scripts: Script[] = [];
  private calls: QueryState[] = [];
  private strict: boolean;

  constructor(opts: FakeSupabaseOptions = {}) {
    this.strict = opts.strict ?? true;
  }

  from(table: string): FakeQueryBuilder {
    return new FakeQueryBuilder(this, { table, op: "select", filters: [] });
  }

  rpc(name: string, args?: Record<string, unknown>): FakeQueryBuilder {
    return new FakeQueryBuilder(this, {
      table: name,
      op: "rpc",
      filters: [],
      rpcArgs: args,
    });
  }

  /** Register a scripted response. Order of registration = order of match preference. */
  scripted(script: Script): this {
    this.scripts.push({ ...script, consumed: false });
    return this;
  }

  /** Convenience: scripted shortcut. */
  on(table: string, op: Op, returns: ScriptedResponse, match?: Script["match"]): this {
    return this.scripted({ table, op, returns, match });
  }

  /** All recorded calls (for assertion). */
  getCalls(): QueryState[] {
    return [...this.calls];
  }

  /** Calls filtered by table+op. */
  callsFor(table: string, op?: Op): QueryState[] {
    return this.calls.filter((c) => c.table === table && (!op || c.op === op));
  }

  /** Reset call log (keeps scripts). */
  resetCalls(): void {
    this.calls = [];
  }

  /** Internal — resolve a builder's final state to a scripted response. */
  _resolve(state: QueryState): ScriptedResponse {
    this.calls.push(state);
    const idx = this.scripts.findIndex((s) =>
      !s.consumed &&
      s.table === state.table &&
      s.op === state.op &&
      (s.match ? s.match(state) : true)
    );
    if (idx < 0) {
      if (!this.strict) return { data: null, error: null };
      throw new Error(
        `fakeSupabase: no script for ${state.op} on "${state.table}". ` +
          `Filters: ${JSON.stringify(state.filters)}. ` +
          `Registered: ${this.scripts.map((s) => `${s.op}:${s.table}`).join(", ") || "(none)"}`,
      );
    }
    const script = this.scripts[idx];
    script.consumed = true;
    // Shape adjustments per terminal modifier.
    let data = script.returns.data;
    if (state.isSingle || state.isMaybeSingle) {
      if (Array.isArray(data)) data = (data[0] as unknown) ?? null;
    }
    return { data: data ?? null, error: script.returns.error ?? null };
  }
}

/** Chainable query builder — implements PromiseLike so `await sb.from(...).select(...).eq(...)` works. */
export class FakeQueryBuilder implements PromiseLike<ScriptedResponse> {
  constructor(private fake: FakeSupabase, private state: QueryState) {}

  // ── selectors / payload ──
  select(cols?: string): this {
    this.state.selectCols = cols ?? "*";
    return this;
  }
  insert(payload: unknown): this {
    this.state.op = "insert";
    this.state.payload = payload;
    return this;
  }
  update(patch: unknown): this {
    this.state.op = "update";
    this.state.payload = patch;
    return this;
  }
  delete(): this {
    this.state.op = "delete";
    return this;
  }
  upsert(payload: unknown, _opts?: unknown): this {
    this.state.op = "upsert";
    this.state.payload = payload;
    return this;
  }

  // ── filters ──
  eq(col: string, val: unknown): this { return this._filter("eq", col, val); }
  neq(col: string, val: unknown): this { return this._filter("neq", col, val); }
  gt(col: string, val: unknown): this { return this._filter("gt", col, val); }
  lt(col: string, val: unknown): this { return this._filter("lt", col, val); }
  gte(col: string, val: unknown): this { return this._filter("gte", col, val); }
  lte(col: string, val: unknown): this { return this._filter("lte", col, val); }
  like(col: string, val: unknown): this { return this._filter("like", col, val); }
  ilike(col: string, val: unknown): this { return this._filter("ilike", col, val); }
  is(col: string, val: unknown): this { return this._filter("is", col, val); }
  in(col: string, val: unknown[]): this { return this._filter("in", col, val); }
  contains(col: string, val: unknown): this { return this._filter("contains", col, val); }
  match(criteria: Record<string, unknown>): this {
    for (const [col, val] of Object.entries(criteria)) this._filter("eq", col, val);
    return this;
  }

  // ── modifiers ──
  limit(n: number): this { this.state.limit = n; return this; }
  order(col: string, opts?: { ascending?: boolean }): this {
    this.state.order = { col, ascending: opts?.ascending };
    return this;
  }
  range(_from: number, _to: number): this { return this; }

  // ── terminals ──
  single(): this { this.state.isSingle = true; return this; }
  maybeSingle(): this { this.state.isMaybeSingle = true; return this; }

  // ── await support ──
  then<R1 = ScriptedResponse, R2 = never>(
    onFulfilled?: ((value: ScriptedResponse) => R1 | PromiseLike<R1>) | null,
    onRejected?: ((reason: unknown) => R2 | PromiseLike<R2>) | null,
  ): PromiseLike<R1 | R2> {
    return new Promise<ScriptedResponse>((resolve, reject) => {
      try {
        resolve(this.fake._resolve(this.state));
      } catch (e) {
        reject(e);
      }
    }).then(onFulfilled, onRejected);
  }

  private _filter(kind: string, col: string, val: unknown): this {
    this.state.filters.push({ kind, col, val });
    return this;
  }
}

/** Convenience constructor. */
export function fakeSupabase(opts?: FakeSupabaseOptions): FakeSupabase {
  return new FakeSupabase(opts);
}
