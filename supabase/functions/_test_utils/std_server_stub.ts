import type { RequestHandler } from "./mock_http.ts";

let captured: RequestHandler | null = null;

export function serve(handler: RequestHandler) {
  captured = handler;
  return {
    shutdown() {},
    finished: Promise.resolve(),
  } as Deno.HttpServer;
}

export function getCapturedHandler(): RequestHandler {
  if (!captured) {
    throw new Error("No std serve handler captured");
  }
  return captured;
}

export function resetCapturedHandler() {
  captured = null;
}
