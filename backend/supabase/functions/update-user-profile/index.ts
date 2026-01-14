import { createClient } from '@supabase/supabase-js'
import { HybridCalculator } from './calculator.ts'

const WEIGHTS: Record<string, number> = {
  view: 1,
  like: 3,
  purchase: 5,
  dislike: -3
};

const calculator = new HybridCalculator({ decayRate: 0.05 });

Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data: queueMsgs, error: qError } = await supabase.rpc('pgmq_pop', {
      queue_name: 'recommendation_updates'
    });

    if (qError) {
        console.error('PGMQ Pop Error:', qError);
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

    console.log(`Processing action: ${action_type} (w:${weight}) for user ${user_id}`);

    const [userRes, partyRes] = await Promise.all([
      supabase.from('user_embeddings').select('embedding').eq('user_id', user_id).maybeSingle(),
      supabase.from('party_embeddings').select('embedding').eq('party_id', party_id).maybeSingle()
    ]);

    if (partyRes.error || !partyRes.data) {
        console.warn(`Party embedding not found for ${party_id}. Skipping.`);
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
    console.error('Error:', errorMessage);
    return new Response(JSON.stringify({ error: errorMessage }), { 
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
})
