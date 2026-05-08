/** Test fixture: custom auth checker that always approves. */
export async function check(
  _req: Request,
): Promise<{ ok: true; reason: string } | { ok: false }> {
  return { ok: true, reason: "mock:always-pass" };
}
