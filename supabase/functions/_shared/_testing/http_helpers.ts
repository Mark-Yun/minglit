// _shared/_testing/http_helpers.ts — Request / Response 보조

export interface MakeRequestOptions {
  method?: string;
  url?: string;
  body?: unknown;
  headers?: Record<string, string>;
}

export function makeRequest(opts: MakeRequestOptions = {}): Request {
  const url = opts.url ?? "http://localhost/test";
  const init: RequestInit = {
    method: opts.method ?? "POST",
    headers: { "content-type": "application/json", ...opts.headers },
  };
  if (opts.body !== undefined) {
    init.body = typeof opts.body === "string" ? opts.body : JSON.stringify(opts.body);
  }
  return new Request(url, init);
}

export async function readJson<T = unknown>(res: Response): Promise<T> {
  return await res.json() as T;
}
