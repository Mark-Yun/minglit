/** Test fixture: custom auth checker that always rejects. */
export async function check(
  _req: Request,
): Promise<{ ok: true; reason: string } | { ok: false }> {
  return { ok: false };
}
