import { createClient } from '@supabase/supabase-js'

Deno.serve(async (_req) => {
  const env = Deno.env.get('ENVIRONMENT')
  if (env !== 'local' && env !== 'development') {
    return new Response(
      JSON.stringify({ error: 'Dev-only function. Blocked in production.' }),
      { status: 403, headers: { 'Content-Type': 'application/json' } },
    )
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    const { data, error } = await supabase
      .from('user_profiles')
      .select('id, name, username')
      .order('username', { ascending: true })

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      )
    }

    return new Response(
      JSON.stringify({ users: data }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
