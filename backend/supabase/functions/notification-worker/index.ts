import { createClient } from '@supabase/supabase-js'
import { runWorkerLoop } from './loop_worker.ts'
import { WorkerUtils } from '../_shared/worker_utils.ts'

Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    
    if (!supabaseUrl || !supabaseKey) {
        throw new Error("Missing environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseKey)
    const utils = new WorkerUtils(supabase, 'q_notifications')

    console.log("Notification Worker v2 Started");

    await runWorkerLoop({ maxDurationMs: 55000, intervalMs: 5000 }, async () => {
      // Use pgmq_read instead of pop for safer retry handling
      const { data: msgs, error } = await supabase.rpc('pgmq_read', {
        queue_name: 'q_notifications',
        vt: 30,
        limit: 1
      });

      if (error) {
        console.error('PGMQ Read Error:', error);
        return false;
      }

      if (!msgs || (Array.isArray(msgs) && msgs.length === 0)) {
        return false; 
      }

      const msg = Array.isArray(msgs) ? msgs[0] : msgs;
      const payload = msg.message;
      const traceId = payload.id;

      // 1. DLQ Check
      if (msg.read_ct > 5) {
        await utils.moveToDLQ(msg.msg_id, payload, "Max retries exceeded (5)");
        return true;
      }

      // 2. Idempotency Check
      if (await utils.isProcessed(traceId)) {
        console.log(`[${traceId}] Already processed. Skipping.`);
        await supabase.rpc('pgmq_delete', { queue_name: 'q_notifications', msg_id: msg.msg_id });
        return true;
      }

      // 3. Time Tracking
      if (payload.meta?.occurred_at) {
        utils.logTimeLag(payload.meta.occurred_at, traceId);
      }

      // 4. Actual Processing
      console.log(`[Notification] Processing event: ${payload.type} (ID: ${traceId})`);
      
      // TODO: Implement notification sending

      // 5. Finalize
      await utils.markProcessed(traceId);
      await supabase.rpc('pgmq_delete', {
        queue_name: 'q_notifications',
        msg_id: msg.msg_id
      });

      return true; 
    });

    return new Response(JSON.stringify({ status: "done" }), {
      headers: { "Content-Type": "application/json" },
    })

  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    console.error("Worker Error:", errorMessage);
    return new Response(JSON.stringify({ error: errorMessage }), { 
      status: 500, 
      headers: { "Content-Type": "application/json" }
    })
  }
})