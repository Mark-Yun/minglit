import { createClient } from '@supabase/supabase-js'
import { OpenAIService } from './openai_service.ts'
import { serializeParty } from './party_serializer.ts'
import { HybridCalculator } from './calculator.ts'
import { WorkerUtils } from '../_shared/worker_utils.ts'
import { initSentry, withSentryHandler } from '../_shared/sentry_utils.ts'

const WEIGHTS: Record<string, number> = {
  view: 0.1,
  like: 0.5,
  purchase: 1.0,
  dislike: -0.5
};

const calculator = new HybridCalculator({ decayRate: 0.05 });

initSentry();

Deno.serve(withSentryHandler(async (req) => {
  console.log("🚀 [Vector Worker] Triggered! Checking environment and auth...");
  try {
    const payload = await req.json().catch(() => ({}));
    const batchSize = payload.batch_size ?? 50;

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || Deno.env.get('SUPABASE_REST_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const openAiKey = Deno.env.get('OPENAI_API_KEY');

    if (!supabaseUrl) throw new Error("Missing SUPABASE_URL");
    if (!supabaseKey) throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY");
    if (!openAiKey) throw new Error("Missing OPENAI_API_KEY (Make sure .env is in function folder)");

    const supabase = createClient(supabaseUrl, supabaseKey);
    const openAi = new OpenAIService(openAiKey);
    const utils = new WorkerUtils(supabase, 'q_vectors');

    // DEBUG LOG
    await supabase.from('debug_logs').insert({
      message: 'Vector Worker Invoked',
      payload: { batchSize, timestamp: new Date().toISOString() }
    });

    // 1. Read Batch from PGMQ
    const { data: messages, error: readError } = await supabase.rpc('pgmq_read', {
      queue_name: 'q_vectors',
      vt: 60, // Increase VT for batch processing
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
    console.log(`Processing v2 batch of ${msgArray.length} messages`);

    // deno-lint-ignore no-explicit-any
    const partyTasks: any[] = [];
    // deno-lint-ignore no-explicit-any
    const interactionTasks: any[] = [];
    const processedMsgIds: number[] = [];

    for (const msg of msgArray) {
      const p = msg.message;
      const traceId = p.id;

      // A. DLQ Check
      if (msg.read_ct > 5) {
        await utils.moveToDLQ(msg.msg_id, p, "Max retries exceeded");
        continue;
      }

      // B. Idempotency Check
      if (await utils.isProcessed(traceId)) {
        console.log(`[${traceId}] Already processed. Skipping.`);
        processedMsgIds.push(msg.msg_id);
        continue;
      }

      // C. Time Tracking
      if (p.meta?.occurred_at) {
        utils.logTimeLag(p.meta.occurred_at, traceId);
      }

      // D. Queue for Processing
      if (p.type === 'party_created') {
        partyTasks.push({ msgId: msg.msg_id, record: p.payload, traceId });
      } else if (p.type === 'user_interaction') {
        interactionTasks.push({ msgId: msg.msg_id, record: p.payload, traceId });
      } else {
          processedMsgIds.push(msg.msg_id);
      }
    }

    // 2. Process Party Vectorization (Efficient OpenAI Batching)
    if (partyTasks.length > 0) {
      try {
        const texts = partyTasks.map(t => serializeParty(t.record));
        console.log(`Requesting ${texts.length} embeddings from OpenAI...`);
        const embeddings = await openAi.generateEmbeddings(texts);
        console.log(`Received ${embeddings.length} embeddings.`);
        
        await supabase.from('debug_logs').insert({
          message: 'OpenAI Result Check',
          payload: { 
            textCount: texts.length, 
            embeddingCount: embeddings.length,
            sample: embeddings.length > 0 ? Array.from(embeddings[0]).slice(0, 5) : null
          }
        });
        
        for (let i = 0; i < partyTasks.length; i++) {
          const t = partyTasks[i];
          const item = {
            party_id: t.record.id,
            embedding: embeddings[i],
            updated_at: new Date().toISOString()
          };
          
          const { error: upsertError } = await supabase.from('party_embeddings').upsert(item);
          if (upsertError) {
            console.error(`Upsert Error for party ${t.record.id}:`, JSON.stringify(upsertError));
          } else {
            console.log(`Successfully saved embedding for party ${t.record.id}`);
            await utils.markProcessed(t.traceId);
            processedMsgIds.push(t.msgId);
          }
        }
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
          
          await utils.markProcessed(task.traceId);
          processedMsgIds.push(task.msgId);
        } else {
          console.warn(`Skipping interaction: Party ${party_id} embedding not found.`);
          processedMsgIds.push(task.msgId);
        }
      } catch (e) {
        console.error(`Interaction Error:`, e);
      }
    }

    // 4. Delete processed messages from queue individually for reliability
    if (processedMsgIds.length > 0) {
      console.log(`Deleting ${processedMsgIds.length} messages from queue...`);
      for (const msgId of processedMsgIds) {
        const { error: delError } = await supabase.rpc('pgmq_delete', {
          queue_name: 'q_vectors',
          msg_id: msgId
        });
        if (delError) console.error(`PGMQ Delete Error for ${msgId}:`, delError);
      }
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
}))
