import { createClient } from '@supabase/supabase-js'
import { runWorkerLoop } from './loop_worker.ts'
import { WorkerUtils } from '../_shared/worker_utils.ts'
import * as jose from 'https://deno.land/x/jose@v4.14.4/index.ts'

// --- Helper: Google OAuth2 Access Token ---
async function getAccessToken(serviceAccountJson: string) {
  try {
    const serviceAccount = JSON.parse(serviceAccountJson);
    const algorithm = 'RS256';
    const privateKey = await jose.importPKCS8(serviceAccount.private_key, algorithm);

    const jwt = await new jose.SignJWT({
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    })
      .setProtectedHeader({ alg: algorithm })
      .setIssuedAt()
      .setExpirationTime('1h')
      .setIssuer(serviceAccount.client_email)
      .sign(privateKey);

    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });

    const data = await response.json();
    return { token: data.access_token, projectId: serviceAccount.project_id };
  } catch (e) {
    console.error('Failed to get Access Token:', e);
    throw e;
  }
}

// --- Helper: Send FCM ---
async function sendFCM(accessToken: string, projectId: string, fcmToken: string, title: string, body: string, data?: any) {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  
  const payload = {
    message: {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data ? data : {}, // Data needs to be string values
    },
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`FCM Send Error [${fcmToken}]:`, errText);
    // If error is 'UNREGISTERED' (token invalid), return specific status to delete it
    if (errText.includes('UNREGISTERED') || errText.includes('INVALID_ARGUMENT')) {
        return 'INVALID';
    }
    return 'ERROR';
  }
  return 'SUCCESS';
}


Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const firebaseServiceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? ''
    
    if (!supabaseUrl || !supabaseKey || !firebaseServiceAccount) {
        throw new Error("Missing environment variables (SUPABASE_URL, KEY, or FIREBASE_SERVICE_ACCOUNT)");
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
      const traceId = payload.id; // Assuming payload has 'id' (UUID of the event or notification)
      const userId = payload.user_id; // Target User

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
      
      try {
        // A. Get Access Token
        const { token: accessToken, projectId } = await getAccessToken(firebaseServiceAccount);

        // B. Get User's FCM Tokens
        const { data: tokens, error: tokenError } = await supabase
            .from('fcm_tokens')
            .select('token')
            .eq('user_id', userId);
        
        if (tokenError) {
            console.error('DB Error fetching tokens:', tokenError);
            throw tokenError;
        }

        if (tokens && tokens.length > 0) {
            // C. Send Notifications
            const sendPromises = tokens.map(async (t) => {
                const status = await sendFCM(
                    accessToken, 
                    projectId, 
                    t.token, 
                    payload.title, 
                    payload.body, 
                    payload.data // deep_link, category etc
                );

                if (status === 'INVALID') {
                    // Clean up invalid token
                    await supabase.from('fcm_tokens').delete().eq('token', t.token);
                    console.log(`Deleted invalid token: ${t.token}`);
                }
            });

            await Promise.all(sendPromises);
            console.log(`Sent notifications to ${tokens.length} devices.`);
        } else {
            console.log(`No FCM tokens found for user ${userId}. Skipping push.`);
        }

        // D. Save to Notification History (DB)
        await supabase.from('user_notifications').insert({
            user_id: userId,
            title: payload.title,
            body: payload.body,
            category: payload.category || 'service',
            deep_link: payload.data?.deep_link,
            metadata: payload.data
        });

      } catch (procError) {
          const msg_ = procError instanceof Error ? procError.message : String(procError);
          console.error(`[${traceId}] Processing Failed: ${msg_}`);
          // Message is NOT deleted — PGMQ visibility timeout (30s) will make it
          // available for retry. After 5 retries, DLQ check above moves it out.
          return true;
      }

      // 5. Finalize (Success)
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