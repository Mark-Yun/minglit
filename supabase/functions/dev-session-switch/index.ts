import { createServiceClient } from '../_shared/supabase_client.ts'
import { initSentry, withHandler } from '../_shared/logger.ts'


initSentry();

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
}

Deno.serve(withHandler(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const env = Deno.env.get('ENVIRONMENT')
  // Fix #1614: "dev" = Supabase dev project (set by supabase-deploy.yml secrets)
  if (env !== 'local' && env !== 'development' && env !== 'dev') {
    return new Response(
      JSON.stringify({ error: 'Dev-only function. Blocked in production.' }),
      { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  try {
    const supabase = createServiceClient()

    const { data, error } = await supabase
      .from('user_profiles')
      .select('id, name, username')
      .order('username', { ascending: true })

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    return new Response(
      JSON.stringify({ users: data }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
}));
