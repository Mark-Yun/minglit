// action/partner_approve.ts — PartnerActionApprove (EF: partner-approve-application)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

export const partnerApproveAction: ActionDef = {
  type: "partner_approve",
  role: "partner",
  ef: "partner-approve-application",

  canExecute(state) {
    const pending = (state.pendingApplications as Array<{ id: string }>) ?? [];
    return pending.length > 0;
  },

  buildPayload(state, rng) {
    const pending = (state.pendingApplications as Array<{ id: string }>) ?? [];
    if (pending.length === 0) {
      throw new Error("partner_approve.buildPayload called when no candidate");
    }
    const idx = Math.floor(rng.next() * pending.length);
    return { application_id: pending[idx].id };
  },
};

registerAction(partnerApproveAction);
