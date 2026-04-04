export type MockError = { message: string } | null;

export type MockResult<T> = {
  data: T | null;
  error: MockError;
};

export type MockTableHandlers = {
  select?: (input: { filters: Record<string, unknown> }) => MockResult<unknown> | Promise<MockResult<unknown>>;
  update?: (input: { values: unknown; filters: Record<string, unknown> }) => MockResult<unknown> | Promise<MockResult<unknown>>;
  insert?: (input: { values: unknown }) => MockResult<unknown> | Promise<MockResult<unknown>>;
  upsert?: (input: { values: unknown }) => MockResult<unknown> | Promise<MockResult<unknown>>;
  delete?: (input: { filters: Record<string, unknown> }) => MockResult<unknown> | Promise<MockResult<unknown>>;
};

export type MockSupabaseHandlers = {
  tables?: Record<string, MockTableHandlers>;
  rpcs?: Record<string, (args: Record<string, unknown>) => MockResult<unknown> | Promise<MockResult<unknown>>>;
  authUser?: { id: string } | null;
  authAdminGetUserById?: (userId: string) => MockResult<{ user: { email: string } | null }> | Promise<MockResult<{ user: { email: string } | null }>>;
};

class MockQueryBuilder {
  private filters: Record<string, unknown> = {};
  private operation: "select" | "update" | "delete" | null = null;
  private values: unknown = null;

  constructor(
    private table: string,
    private handlers: MockSupabaseHandlers,
  ) {}

  select(_columns?: string) {
    this.operation = "select";
    return this;
  }

  update(values: unknown) {
    this.operation = "update";
    this.values = values;
    return this;
  }

  insert(values: unknown) {
    const handler = this.handlers.tables?.[this.table]?.insert;
    return Promise.resolve(handler ? handler({ values }) : { data: null, error: null });
  }

  upsert(values: unknown) {
    const handler = this.handlers.tables?.[this.table]?.upsert;
    return Promise.resolve(handler ? handler({ values }) : { data: null, error: null });
  }

  delete() {
    this.operation = "delete";
    return this;
  }

  eq(column: string, value: unknown) {
    this.filters[column] = value;
    return this;
  }

  in(column: string, values: unknown[]) {
    this.filters[column] = values;
    return this;
  }

  limit(_count: number) {
    return this;
  }

  not(column: string, _operator: string, _value: unknown) {
    // no-op filter for mock — select handler receives all data regardless
    void column;
    return this;
  }

  single() {
    return this.execute();
  }

  maybeSingle() {
    return this.execute();
  }

  then<TResult1 = MockResult<unknown>, TResult2 = never>(
    onfulfilled?: ((value: MockResult<unknown>) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): Promise<TResult1 | TResult2> {
    return this.execute().then(onfulfilled, onrejected);
  }

  private async execute(): Promise<MockResult<unknown>> {
    if (this.operation === "select") {
      const handler = this.handlers.tables?.[this.table]?.select;
      return await Promise.resolve(handler ? handler({ filters: this.filters }) : { data: null, error: null });
    }
    if (this.operation === "update") {
      const handler = this.handlers.tables?.[this.table]?.update;
      return await Promise.resolve(
        handler ? handler({ values: this.values, filters: this.filters }) : { data: null, error: null },
      );
    }
    if (this.operation === "delete") {
      const handler = this.handlers.tables?.[this.table]?.delete;
      return await Promise.resolve(
        handler ? handler({ filters: this.filters }) : { data: null, error: null },
      );
    }
    return { data: null, error: null };
  }
}

export function createMockSupabaseClient(handlers: MockSupabaseHandlers = {}) {
  return {
    from: (table: string) => new MockQueryBuilder(table, handlers),
    rpc: (name: string, args: Record<string, unknown>) => {
      const handler = handlers.rpcs?.[name];
      return Promise.resolve(handler ? handler(args) : { data: null, error: null });
    },
    auth: {
      getUser: (_token?: string) =>
        Promise.resolve({ data: { user: handlers.authUser ?? null }, error: null }),
      admin: {
        getUserById: (userId: string) => {
          const handler = handlers.authAdminGetUserById;
          return Promise.resolve(
            handler
              ? handler(userId)
              : { data: { user: null }, error: null },
          );
        },
      },
    },
  };
}
