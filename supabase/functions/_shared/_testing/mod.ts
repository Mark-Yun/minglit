// _shared/_testing/mod.ts — public re-exports for handler unit tests

export {
  fakeSupabase,
  FakeQueryBuilder,
  FakeSupabase,
  type Op,
  type PgError,
  type QueryState,
  type Script,
  type ScriptedResponse,
} from "./fake_supabase.ts";

export { makeCtx, type MakeCtxOptions } from "./fake_ef_context.ts";
export { makeRequest, readJson, type MakeRequestOptions } from "./http_helpers.ts";
export { runHandler, type Handler, type RunHandlerOptions } from "./handler_runner.ts";

export { buildApplication, type ApplicationFixture } from "./fixtures/application.ts";
export { buildEvent, type EventFixture } from "./fixtures/event.ts";
export { buildTicket, type TicketFixture } from "./fixtures/ticket.ts";
export { buildUserProfile, type UserProfileFixture } from "./fixtures/user.ts";
