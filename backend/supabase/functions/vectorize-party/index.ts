import { createClient } from '@supabase/supabase-js'
import { OpenAIService } from './openai_service.ts'
import { serializeParty } from './party_serializer.ts'

Deno.serve(async (req) => {
  try {
    const payload = await req.json()
    // Supabase Database Webhook payload structure: { type: 'INSERT'|'UPDATE', table: 'parties', record: { ... }, ... }
    // Or direct invocation: { record: { ... } }
    const record = payload.record ?? payload;

    if (!record || !record.id) {
      return new Response(JSON.stringify({ error: "No valid record provided" }), { 
        status: 400,
        headers: { "Content-Type": "application/json" }
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const openAiKey = Deno.env.get('OPENAI_API_KEY') ?? ''

    if (!supabaseUrl || !supabaseKey || !openAiKey) {
        throw new Error("Missing environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseKey)
    const openAi = new OpenAIService(openAiKey)

    // 1. Serialize
    const text = serializeParty(record)
    console.log(`Vectorizing party ${record.id}: ${text.substring(0, 50)}...`);
    
    // 2. Generate Embedding
    const embedding = await openAi.generateEmbedding(text)

    // 3. Save to DB
    const { error } = await supabase
      .from('party_embeddings')
      .upsert({
        party_id: record.id,
        embedding: embedding,
        updated_at: new Date().toISOString(),
      })

    if (error) {
        console.error('Supabase Write Error:', error);
        throw error;
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    })

  } catch (err: any) {
    console.error('Error:', err);
    return new Response(JSON.stringify({ error: err.message ?? "Unknown error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})