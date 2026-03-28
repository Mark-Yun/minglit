import { stub } from "@std/testing/mock";
import { getCapturedHandler, resetCapturedHandler } from "./std_server_stub.ts";

export type RequestHandler = (req: Request) => Response | Promise<Response>;

export type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

export type FetchRoute = {
  matcher: string | RegExp | ((req: Request) => boolean);
  handler: (req: Request) => Response | Promise<Response>;
};

export function jsonResponse(body: unknown, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers);
  if (!headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  return new Response(JSON.stringify(body), { ...init, headers });
}

export function textResponse(body: string, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers);
  if (!headers.has("Content-Type")) {
    headers.set("Content-Type", "text/plain");
  }
  return new Response(body, { ...init, headers });
}

export function jsonRequest(url: string, body: unknown, init: RequestInit = {}): Request {
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "application/json");
  return new Request(url, {
    ...init,
    method: init.method ?? "POST",
    headers,
    body: JSON.stringify(body),
  });
}

export function textRequest(url: string, body: string, init: RequestInit = {}): Request {
  return new Request(url, {
    ...init,
    method: init.method ?? "POST",
    body,
  });
}

export function authenticatedJsonRequest(url: string, body: unknown, init: RequestInit = {}): Request {
  const headers = new Headers(init.headers);
  if (!headers.has("Authorization")) {
    headers.set("Authorization", "Bearer test-token");
  }
  headers.set("Content-Type", "application/json");
  return new Request(url, {
    ...init,
    method: init.method ?? "POST",
    headers,
    body: JSON.stringify(body),
  });
}

export async function readJson(response: Response) {
  return await response.json();
}

export function createFetchMock(
  routes: FetchRoute[],
  fallback?: (req: Request) => Response | Promise<Response>,
) {
  const calls: Array<{ url: string; method: string; body: string | null }> = [];

  const fetchMock: FetchLike = async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    const req = new Request(input, init);
    let bodyText: string | null = null;
    try {
      bodyText = await req.clone().text();
    } catch {
      bodyText = null;
    }
    calls.push({ url: req.url, method: req.method, body: bodyText });

    for (const route of routes) {
      const match =
        typeof route.matcher === "string"
          ? req.url.includes(route.matcher)
          : route.matcher instanceof RegExp
          ? route.matcher.test(req.url)
          : route.matcher(req);
      if (match) {
        return await route.handler(req);
      }
    }

    if (fallback) {
      return await fallback(req);
    }
    throw new Error(`Unhandled fetch: ${req.method} ${req.url}`);
  };

  return { fetchMock, calls };
}

export async function withMockedFetch<T>(fetchMock: FetchLike, fn: () => Promise<T>) {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = fetchMock as typeof fetch;
  try {
    return await fn();
  } finally {
    globalThis.fetch = originalFetch;
  }
}

export async function withNoIntervals<T>(fn: () => Promise<T>) {
  const originalSetInterval = globalThis.setInterval;
  const originalClearInterval = globalThis.clearInterval;

  globalThis.setInterval = ((callback: () => void) => {
    callback();
    return 0 as unknown as number;
  }) as typeof setInterval;
  globalThis.clearInterval = ((_id?: number) => {}) as typeof clearInterval;

  try {
    return await fn();
  } finally {
    globalThis.setInterval = originalSetInterval;
    globalThis.clearInterval = originalClearInterval;
  }
}

export async function withEnv<T>(
  values: Record<string, string | undefined>,
  fn: () => T | Promise<T>,
): Promise<T> {
  const previous = new Map<string, string | undefined>();
  for (const [key, value] of Object.entries(values)) {
    previous.set(key, Deno.env.get(key));
    if (value === undefined) {
      Deno.env.delete(key);
    } else {
      Deno.env.set(key, value);
    }
  }

  try {
    return await fn();
  } finally {
    for (const [key, value] of previous.entries()) {
      if (value === undefined) {
        Deno.env.delete(key);
      } else {
        Deno.env.set(key, value);
      }
    }
  }
}

export async function captureServeHandler(moduleUrl: string | URL): Promise<RequestHandler> {
  let captured: RequestHandler | undefined;

  resetCapturedHandler();

  const serveOwner = Deno as unknown as {
    serve: (...args: unknown[]) => Deno.HttpServer;
  };

  const originalSetInterval = globalThis.setInterval;
  const originalClearInterval = globalThis.clearInterval;
  globalThis.setInterval = ((callback: () => void) => {
    callback();
    return 0 as unknown as number;
  }) as typeof setInterval;
  globalThis.clearInterval = ((_id?: number) => {}) as typeof clearInterval;

  const serveStub = stub(serveOwner, "serve", (arg1: unknown, arg2?: unknown) => {
    const handler =
      typeof arg1 === "function"
        ? (arg1 as RequestHandler)
        : (arg1 as { handler?: RequestHandler })?.handler ??
          (typeof arg2 === "function" ? (arg2 as RequestHandler) : undefined);

    if (!handler) {
      throw new Error("No handler provided to Deno.serve");
    }
    if (!captured) {
      captured = handler;
    }

    return {
      shutdown() {},
      finished: Promise.resolve(),
    } as Deno.HttpServer;
  });

  try {
    const specifier = typeof moduleUrl === "string" ? moduleUrl : moduleUrl.toString();
    await import(`${specifier}?test=${crypto.randomUUID()}`);
  } finally {
    serveStub.restore();
    globalThis.setInterval = originalSetInterval;
    globalThis.clearInterval = originalClearInterval;
  }

  if (!captured) {
    try {
      return getCapturedHandler();
    } catch {
      throw new Error(`No handler captured from ${moduleUrl}`);
    }
  }

  return captured;
}
