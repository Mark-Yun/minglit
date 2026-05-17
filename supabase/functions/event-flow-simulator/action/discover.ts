// action/discover.ts — UserActionDiscover (EF: user-event-feed, read-only)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

export const discoverAction: ActionDef = {
  type: "user_discover",
  role: "user",
  ef: "user-event-feed",

  canExecute(_state) {
    // Read-only — 항상 실행 가능 (rate 가 sampling 빈도 조절)
    return true;
  },

  buildPayload(_state, _rng) {
    return { limit: 20 };
  },
};

registerAction(discoverAction);
