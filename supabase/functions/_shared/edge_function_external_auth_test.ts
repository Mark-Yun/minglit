// Tests for external_auth patterns: ip_allowlist, hmac, custom (#2186)
import { assertEquals } from "@std/assert";
import { checkExternalAuth } from "./edge_function.ts";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeRequest(opts: {
  method?: string;
  headers?: Record<string, string>;
  body?: string;
}): Request {
  return new Request("http://localhost/", {
    method: opts.method ?? "POST",
    headers: opts.headers,
    body: opts.body,
  });
}

async function computeHmac(secret: string, body: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
  return Array.from(new Uint8Array(mac))
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
}

// ---------------------------------------------------------------------------
// ip_allowlist (regression — existing behaviour must not change)
// ---------------------------------------------------------------------------

Deno.test("checkExternalAuth: ip_allowlist — matching x-real-ip passes", async () => {
  const req = makeRequest({ headers: { "x-real-ip": "52.78.100.19" } });
  const result = await checkExternalAuth(
    req,
    { type: "ip_allowlist", ips: ["52.78.100.19"] },
    "test-fn",
  );
  assertEquals(result, { ok: true, reason: "ip_allowlist:52.78.100.19" });
});

Deno.test("checkExternalAuth: ip_allowlist — unlisted IP fails", async () => {
  const req = makeRequest({ headers: { "x-real-ip": "1.2.3.4" } });
  const result = await checkExternalAuth(
    req,
    { type: "ip_allowlist", ips: ["52.78.100.19"] },
    "test-fn",
  );
  assertEquals(result, { ok: false });
});

// ---------------------------------------------------------------------------
// hmac
// ---------------------------------------------------------------------------

Deno.test("checkExternalAuth: hmac — raw hex signature passes", async () => {
  const secret = "test-secret";
  const body = '{"imp_uid":"test123"}';
  const sig = await computeHmac(secret, body);

  Deno.env.set("TEST_WEBHOOK_SECRET", secret);
  try {
    const req = makeRequest({
      body,
      headers: { "x-webhook-signature": sig },
    });
    const result = await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-webhook-signature" },
      "test-fn",
    );
    assertEquals(result, { ok: true, reason: "hmac:x-webhook-signature" });
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

Deno.test("checkExternalAuth: hmac — sha256=<hex> prefixed signature passes (PortOne V2 format)", async () => {
  const secret = "portone-secret";
  const body = '{"status":"paid"}';
  const hex = await computeHmac(secret, body);

  Deno.env.set("TEST_WEBHOOK_SECRET", secret);
  try {
    const req = makeRequest({
      body,
      headers: { "x-portone-signature-v2": `sha256=${hex}` },
    });
    const result = await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-portone-signature-v2" },
      "test-fn",
    );
    assertEquals(result, { ok: true, reason: "hmac:x-portone-signature-v2" });
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

// Fix #2336: verifies that a signature differing by one byte is rejected.
// Regression guard for CWE-208 timing attack: string === would accept identical
// prefixes if short-circuited; crypto.subtle.verify must reject partial matches.
Deno.test("checkExternalAuth: hmac — signature with flipped last byte fails (timing-safe guard)", async () => {
  const secret = "test-secret";
  const body = '{"status":"paid"}';
  const validHex = await computeHmac(secret, body);
  // Flip the last byte of the valid hex signature.
  const lastByte = parseInt(validHex.slice(-2), 16);
  const flippedHex = validHex.slice(0, -2) + ((lastByte ^ 0xff) & 0xff).toString(16).padStart(2, "0");

  Deno.env.set("TEST_WEBHOOK_SECRET", secret);
  try {
    const req = makeRequest({
      body,
      headers: { "x-sig": flippedHex },
    });
    const result = await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-sig" },
      "test-fn",
    );
    assertEquals(result, { ok: false });
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

// Fix #2336: odd-length hex is invalid and must fail before byte decoding.
Deno.test("checkExternalAuth: hmac — odd-length hex signature fails", async () => {
  Deno.env.set("TEST_WEBHOOK_SECRET", "some-secret");
  try {
    const req = makeRequest({
      body: '{}',
      headers: { "x-sig": "abc" },  // odd length
    });
    const result = await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-sig" },
      "test-fn",
    );
    assertEquals(result, { ok: false });
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

// Fix #2336: even-length non-hex string must fail — parseInt("aZ",16)===10 silently
// parses partial chars; regex guard is required to reject malformed input.
Deno.test("checkExternalAuth: hmac — even-length non-hex signature fails", async () => {
  Deno.env.set("TEST_WEBHOOK_SECRET", "some-secret");
  try {
    const req = makeRequest({
      body: '{}',
      headers: { "x-sig": "aZ" },  // even length but "Z" is not hex
    });
    const result = await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-sig" },
      "test-fn",
    );
    assertEquals(result, { ok: false });
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

Deno.test("checkExternalAuth: hmac — wrong secret fails", async () => {
  const body = '{"event":"payment"}';
  const sig = await computeHmac("correct-secret", body);

  Deno.env.set("TEST_WEBHOOK_SECRET", "wrong-secret");
  try {
    const req = makeRequest({
      body,
      headers: { "x-sig": sig },
    });
    const result = await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-sig" },
      "test-fn",
    );
    assertEquals(result, { ok: false });
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

Deno.test("checkExternalAuth: hmac — missing signature header fails", async () => {
  Deno.env.set("TEST_WEBHOOK_SECRET", "some-secret");
  try {
    const req = makeRequest({ body: '{}' });
    const result = await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-sig" },
      "test-fn",
    );
    assertEquals(result, { ok: false });
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

Deno.test("checkExternalAuth: hmac — env var not set fails", async () => {
  Deno.env.delete("TEST_WEBHOOK_SECRET");
  const req = makeRequest({
    body: '{}',
    headers: { "x-sig": "somehex" },
  });
  const result = await checkExternalAuth(
    req,
    { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-sig" },
    "test-fn",
  );
  assertEquals(result, { ok: false });
});

Deno.test("checkExternalAuth: hmac — original request body still readable after check", async () => {
  const secret = "s3cr3t";
  const body = '{"amount":9900}';
  const sig = await computeHmac(secret, body);

  Deno.env.set("TEST_WEBHOOK_SECRET", secret);
  try {
    const req = makeRequest({
      body,
      headers: { "x-sig": sig },
    });
    await checkExternalAuth(
      req,
      { type: "hmac", secret_env: "TEST_WEBHOOK_SECRET", header: "x-sig" },
      "test-fn",
    );
    // Handler must still be able to read the body
    const readBody = await req.text();
    assertEquals(readBody, body);
  } finally {
    Deno.env.delete("TEST_WEBHOOK_SECRET");
  }
});

// ---------------------------------------------------------------------------
// custom
// ---------------------------------------------------------------------------

Deno.test("checkExternalAuth: custom — always-pass module returns ok:true", async () => {
  const moduleUrl = new URL("../_test_utils/mock_custom_auth_pass.ts", import.meta.url).href;
  const req = makeRequest({});
  const result = await checkExternalAuth(
    req,
    { type: "custom", module: moduleUrl },
    "test-fn",  // fnName unused when module is an absolute URL
  );
  assertEquals(result, { ok: true, reason: "mock:always-pass" });
});

Deno.test("checkExternalAuth: custom — always-fail module returns ok:false", async () => {
  const moduleUrl = new URL("../_test_utils/mock_custom_auth_fail.ts", import.meta.url).href;
  const req = makeRequest({});
  const result = await checkExternalAuth(
    req,
    { type: "custom", module: moduleUrl },
    "test-fn",
  );
  assertEquals(result, { ok: false });
});
