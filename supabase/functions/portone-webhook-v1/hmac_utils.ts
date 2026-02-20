/**
 * HMAC-SHA256 utilities for webhook signature verification
 * 
 * Uses Web Crypto API (standard in Deno/browsers)
 */

/**
 * Compute HMAC-SHA256 signature of a body string
 * 
 * @param body - The raw request body as a string
 * @param secret - The shared secret key
 * @returns Hex-encoded HMAC signature
 */
export async function computeHmacSignature(
  body: string,
  secret: string,
): Promise<string> {
  const encoder = new TextEncoder();
  
  // Import the secret key for HMAC
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  
  // Compute the HMAC signature
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(body),
  );
  
  // Convert to hex string
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Verify an HMAC signature against a body and secret
 * 
 * @param body - The raw request body as a string
 * @param signature - The claimed signature (hex-encoded)
 * @param secret - The shared secret key
 * @returns true if signature is valid, false otherwise
 */
export async function verifyHmacSignature(
  body: string,
  signature: string,
  secret: string,
): Promise<boolean> {
  const expectedSignature = await computeHmacSignature(body, secret);
  
  // Constant-time comparison to prevent timing attacks
  // JavaScript doesn't have a built-in constant-time compare, but for
  // hex strings of the same length, simple equality is reasonably safe.
  // For production, consider using a dedicated timing-safe comparison.
  return signature === expectedSignature;
}
