// _shared/_testing/handler_runner.ts — handler 직접 호출 helper

import type { EFContext } from "../edge_function.ts";
import { makeRequest, type MakeRequestOptions } from "./http_helpers.ts";

export type Handler = (req: Request, ctx: EFContext) => Promise<Response>;

export interface RunHandlerOptions extends MakeRequestOptions {
  ctx: EFContext;
}

/** Build a Request from opts and invoke the handler with the given ctx. */
export function runHandler(handler: Handler, opts: RunHandlerOptions): Promise<Response> {
  const req = makeRequest(opts);
  return handler(req, opts.ctx);
}
