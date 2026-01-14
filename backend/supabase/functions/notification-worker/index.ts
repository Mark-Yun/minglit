import { createClient } from '@supabase/supabase-js'
import { runWorkerLoop } from './loop_worker.ts'

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    
    if (!supabaseUrl || !supabaseKey) {
        throw new Error("Missing environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseKey)

    console.log("Notification Worker Started");

    // Run loop for 55 seconds, polling every 5 seconds
    await runWorkerLoop({ maxDurationMs: 55000, intervalMs: 5000 }, async () => {
      // Consume from q_notifications (Pop 1 message)
      const { data: msgs, error } = await supabase.rpc('pgmq_pop', {
        queue_name: 'q_notifications'
      });

      if (error) {
        console.error('PGMQ Pop Error:', error);
        return false;
      }

      if (!msgs || (Array.isArray(msgs) && msgs.length === 0)) {
        return false; // Queue empty
      }

      const msg = Array.isArray(msgs) ? msgs[0] : msgs;
      const payload = msg.message;
      
      console.log(`[Notification] Processing event: ${payload.event_type} (ID: ${msg.msg_id})`);

      // TODO: Implement actual notification sending logic (FCM, Email, etc.)
      // Example: 
      // if (payload.event_type === 'party_created') { sendAdminAlert(payload.record); }

      return true; // Work done
    });

    console.log("Notification Worker Finished (Timeout Reached)");

    return new Response(JSON.stringify({ status: "done" }), {
      headers: { "Content-Type": "application/json" },
    })

  } catch (err: any) {
    console.error("Worker Error:", err);
    return new Response(JSON.stringify({ error: err.message }), { 
      status: 500, 
      headers: { "Content-Type": "application/json" }
    })
  }
})