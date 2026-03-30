// NOTE: This worker is currently unused; the `recommendation_updates` queue
// is not created by migrations. Keep for reference, but clean up when the
// queue is removed or renamed.
import { createServiceClient } from '../_shared/supabase_client.ts'
import { HybridCalculator } from './calculator.ts'
import { initSentry, withHandler, log } from '../_shared/logger.ts'

const FN = "profile-update";

const WEIGHTS: Record<string, number> = {
  view: 1,
  like: 3,
  purchase: 5,
  dislike: -3
};

const calculator = new HybridCalculator({ decayRate: 0.05 });

initSentry();

Deno.serve(withHandler(async (_req) => {
  try {
    const supabase = createServiceClient()

    const { data: queueMsgs, error: qError } = await supabase.rpc('pgmq_pop', {
      queue_name: 'recommendation_updates'
    });

    if (qError) {
        log({ function: FN, level: "error", message: "PGMQ Pop Error", metadata: { detail: qError } });
        throw qError;
    }
    
    if (!queueMsgs || (Array.isArray(queueMsgs) && queueMsgs.length === 0)) {
      return new Response(JSON.stringify({ message: "Queue is empty" }), { 
        status: 200,
        headers: { "Content-Type": "application/json" }
      });
    }

    const msg = Array.isArray(queueMsgs) ? queueMsgs[0] : queueMsgs;
    const { user_id, party_id, action_type } = msg.message;
    const weight = WEIGHTS[action_type] ?? 0;

    // Fix #167: user_id 평문 로깅 방지
log({ function: FN, level: "info", message: `Processing action: ${action_type} (w:${weight}) for user ${typeof user_id === "string" ? user_id.slice(0, 8) : "unknown"}...` });

    const [userRes, partyRes] = await Promise.all([
      supabase.from('user_embeddings').select('embedding').eq('user_id', user_id).maybeSingle(),
      supabase.from('party_embeddings').select('embedding').eq('party_id', party_id).maybeSingle()
    ]);

    if (partyRes.error || !partyRes.data) {
        log({ function: FN, level: "warn", message: `Party embedding not found for ${party_id}. Skipping.` });
        return new Response(JSON.stringify({ error: "Party embedding missing" }), { status: 404 });
    }

    const oldVector = userRes.data?.embedding ?? new Array(1536).fill(0);
    const actionVector = partyRes.data.embedding;

    const newVector = calculator.calculate(oldVector, actionVector, weight);

    const { error: upError } = await supabase
      .from('user_embeddings')
      .upsert({
        user_id,
        embedding: newVector,
        updated_at: new Date().toISOString()
      });

    if (upError) throw upError;

    return new Response(JSON.stringify({ 
      success: true, 
      processed: { user_id, action_type, weight } 
    }), { headers: { "Content-Type": "application/json" } });

  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    log({ function: FN, level: "error", message: "Error", metadata: { detail: errorMessage } });
    return new Response(JSON.stringify({ error: errorMessage }), { 
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
}))
