// action/partner_reject.ts — PartnerActionReject (EF: partner-reject-application)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

export const partnerRejectAction: ActionDef = {
  type: "partner_reject",
  role: "partner",
  ef: "partner-reject-application",

  canExecute(state) {
    const pending = (state.pendingApplications as Array<{ id: string }>) ?? [];
    return pending.length > 0;
  },

  buildPayload(state, rng) {
    const pending = (state.pendingApplications as Array<{ id: string }>) ?? [];
    if (pending.length === 0) {
      throw new Error("partner_reject.buildPayload called when no candidate");
    }
    const idx = Math.floor(rng.next() * pending.length);
    return { application_id: pending[idx].id };
  },
};

registerAction(partnerRejectAction);
