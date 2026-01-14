import { createClient } from '@supabase/supabase-js'
import { OpenAIService } from './openai_service.ts'
import { serializeParty } from './party_serializer.ts'
import { HybridCalculator } from './calculator.ts'

const WEIGHTS: Record<string, number> = {
  view: 0.1,
  like: 0.5,
  purchase: 1.0,
  dislike: -0.5
};

const calculator = new HybridCalculator({ decayRate: 0.05 });

Deno.serve(async (req) => {
  try {
    const payload = await req.json().catch(() => ({}));
    const batchSize = payload.batch_size ?? 50;

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const openAiKey = Deno.env.get('OPENAI_API_KEY') ?? '';

    if (!supabaseUrl || !supabaseKey || !openAiKey) {
        throw new Error("Missing environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseKey);
    const openAi = new OpenAIService(openAiKey);

    // 1. Read Batch from PGMQ
    // pgmq.read(queue_name, vt, limit)
    const { data: messages, error: readError } = await supabase.rpc('pgmq_read', {
      queue_name: 'q_vectors',
      vt: 30, 
      limit: batchSize
    });

    if (readError) {
        console.error('PGMQ Read Error:', readError);
        throw readError;
    }
    
    if (!messages || (Array.isArray(messages) && messages.length === 0)) {
      return new Response(JSON.stringify({ processed: 0 }), { 
        headers: { "Content-Type": "application/json" }
      });
    }

    const msgArray = Array.isArray(messages) ? messages : [messages];
    console.log(`Processing batch of ${msgArray.length} messages`);

    // deno-lint-ignore no-explicit-any
    const partyTasks: any[] = [];
    // deno-lint-ignore no-explicit-any
    const interactionTasks: any[] = [];
    const processedMsgIds: number[] = [];

    for (const msg of msgArray) {
      const p = msg.message;
      if (p.event_type === 'party_created') {
        partyTasks.push({ msgId: msg.msg_id, record: p.record });
      } else if (p.event_type === 'user_interaction') {
        interactionTasks.push({ msgId: msg.msg_id, record: p.record });
      } else {
          // Unknown event, just mark as processed to clear queue
          processedMsgIds.push(msg.msg_id);
      }
    }

    // 2. Process Party Vectorization (Efficient OpenAI Batching)
    if (partyTasks.length > 0) {
      try {
        const texts = partyTasks.map(t => serializeParty(t.record));
        const embeddings = await openAi.generateEmbeddings(texts);
        
        const upserts = partyTasks.map((t, i) => ({
          party_id: t.record.id,
          embedding: embeddings[i],
          updated_at: new Date().toISOString()
        }));

        const { error } = await supabase.from('party_embeddings').upsert(upserts);
        if (error) throw error;
        
        partyTasks.forEach(t => processedMsgIds.push(t.msgId));
      } catch (e) {
        console.error('Party Vectorization Error:', e);
      }
    }

    // 3. Process User Interactions
    for (const task of interactionTasks) {
      try {
        const { user_id, party_id, action_type } = task.record;
        const weight = WEIGHTS[action_type] ?? 0;

        const [userRes, partyRes] = await Promise.all([
          supabase.from('user_embeddings').select('embedding').eq('user_id', user_id).maybeSingle(),
          supabase.from('party_embeddings').select('embedding').eq('party_id', party_id).maybeSingle()
        ]);

        if (partyRes.data && partyRes.data.embedding) {
          const oldVector = userRes.data?.embedding ?? new Array(1536).fill(0);
          const newVector = calculator.calculate(oldVector, partyRes.data.embedding, weight);
          
          const { error } = await supabase.from('user_embeddings').upsert({
            user_id,
            embedding: newVector,
            updated_at: new Date().toISOString()
          });
          if (error) throw error;
          processedMsgIds.push(task.msgId);
        } else {
          console.warn(`Skipping interaction for user ${user_id}: Party ${party_id} embedding not found.`);
          // We can delete it or let it retry. Let's delete to avoid infinite loop if party is deleted.
          processedMsgIds.push(task.msgId);
        }
      } catch (e) {
        console.error(`Interaction Error for user ${task.record.user_id}:`, e);
      }
    }

    // 4. Delete processed messages from queue
    if (processedMsgIds.length > 0) {
      const { error: delError } = await supabase.rpc('pgmq_delete_batch', {
        queue_name: 'q_vectors',
        msg_ids: processedMsgIds
      });
      if (delError) console.error('PGMQ Delete Error:', delError);
    }

    return new Response(JSON.stringify({ processed: processedMsgIds.length }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    console.error('Vector Worker Error:', errorMessage);
    return new Response(JSON.stringify({ error: errorMessage }), { 
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
})