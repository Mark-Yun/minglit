import { createClient } from '@supabase/supabase-js'
import { runWorkerLoop } from './loop_worker.ts'
import { WorkerUtils } from '../_shared/worker_utils.ts'
import * as jose from 'https://deno.land/x/jose@v4.14.4/index.ts'
import { initSentry, withSentryHandler } from '../_shared/sentry_utils.ts'

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

// --- Schema A: event_type → Korean title/body template ---
const NOTIFICATION_TEMPLATES: Record<string, (data: Record<string, unknown>) => { title: string; body: string }> = {
  party_created: (_d) => ({
    title: '[새 파티]',
    body: '새로운 파티가 생성되었습니다.',
  }),
  user_interaction: (_d) => ({
    title: '[프로필 업데이트]',
    body: '프로필이 업데이트되었습니다.',
  }),
  application_approved: (d) => ({
    title: '[이벤트 참가 확정]',
    body: `${(d.event_title as string) || '이벤트'} 참가가 확정되었습니다.`,
  }),
  application_rejected: (d) => ({
    title: '[이벤트 신청 결과]',
    body: `${(d.event_title as string) || '이벤트'} 신청이 반려되었습니다.`,
  }),
  event_updated: (d) => ({
    title: '[이벤트 업데이트]',
    body: `${(d.title as string) || '이벤트'} 정보가 변경되었습니다.`,
  }),
  event_cancelled: (d) => ({
    title: '[이벤트 취소]',
    body: `${(d.title as string) || '이벤트'}이(가) 취소되었습니다.`,
  }),
  new_application: (d) => ({
    title: '[새 이벤트 신청]',
    body: `${(d.event_title as string) || '이벤트'}에 새로운 신청이 도착했습니다.`,
  }),
  verification_result: (_d) => ({
    title: '[인증 결과]',
    body: '인증 결과가 도착했습니다.',
  }),
  event_reminder: (d) => ({
    title: '[이벤트 리마인더]',
    body: `${(d.event_title as string) || '이벤트'}이(가) 1시간 후 시작됩니다.`,
  }),
};

// --- Helper: Resolve affected user_id for Schema A events ---
async function getAffectedUserId(supabase: any, eventType: string, data: Record<string, unknown>): Promise<string | null> {
  // Most events: user_id is in data directly
  if (data.user_id) return data.user_id as string;
  // new_application: notify the event partner (via party)
  if (eventType === 'new_application' && data.event_id) {
    const { data: event } = await supabase
      .from('events')
      .select('parties(partner_id)')
      .eq('id', data.event_id)
      .single();
    return event?.parties?.partner_id || null;
  }
  return null;
}

// --- Helper: Fan-out FCM + DB notification to all approved event participants ---
async function sendToAllParticipants(
  supabase: any,
  eventId: string,
  title: string,
  body: string,
  category: string,
  accessToken: string,
  projectId: string,
) {
  const { data: applications } = await supabase
    .from('event_applications')
    .select('user_id')
    .eq('event_id', eventId)
    .eq('status', 'approved');

  if (!applications || applications.length === 0) {
    console.log(`[fan-out] No approved participants for event ${eventId}`);
    return;
  }

  console.log(`[fan-out] Sending to ${applications.length} participants for event ${eventId}`);

  for (const app of applications) {
    const { data: tokens } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', app.user_id);

    if (tokens && tokens.length > 0) {
      for (const t of tokens) {
        const status = await sendFCM(accessToken, projectId, t.token, title, body);
        if (status === 'INVALID') {
          await supabase.from('fcm_tokens').delete().eq('token', t.token);
          console.log(`Deleted invalid token: ${t.token}`);
        }
      }
    }

    await supabase.from('user_notifications').insert({
      user_id: app.user_id,
      title,
      body,
      category,
    });
  }
}


initSentry();

Deno.serve(withSentryHandler(async (_req) => {
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

      // --- Schema Detection ---
      // Schema A: produced by produce_event() — has event_id / schema_version
      // Schema B: produced by legacy DB triggers — has title directly
      const isSchemaA = 'event_id' in payload || 'schema_version' in payload;
      const traceId = isSchemaA ? (payload.event_id as string) : (payload.id as string);

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

      // 3. Time Tracking (Schema A: payload.occurred_at as integer, Schema B: payload.meta.occurred_at as ISO string)
      let occurredAtUnix: number | null = null;
      if (isSchemaA && typeof payload.occurred_at === 'number') {
        // Schema A: occurred_at is Unix epoch integer
        occurredAtUnix = payload.occurred_at as number;
      } else if (payload.meta?.occurred_at && typeof payload.meta.occurred_at === 'string') {
        // Schema B: occurred_at is ISO string, parse to Unix epoch
        const isoDate = new Date(payload.meta.occurred_at as string);
        occurredAtUnix = Math.floor(isoDate.getTime() / 1000);
      }
      if (occurredAtUnix !== null) {
        utils.logTimeLag(occurredAtUnix, traceId);
      }

      // 4. Actual Processing
      console.log(`[Notification] Processing ${isSchemaA ? 'Schema A' : 'Schema B'} event (ID: ${traceId})`);
      
      try {
        let userId: string | null;
        let title: string;
        let body: string;
        let category: string;
        let deepLink: string | undefined;

        if (isSchemaA) {
          // --- Schema A: structured payload from produce_event() ---
          const eventType = payload.event_type as string;
          const data = (payload.data as Record<string, unknown>) || {};

          const template = NOTIFICATION_TEMPLATES[eventType];
          if (!template) {
            console.warn(`[${traceId}] Unknown event_type: ${eventType}. Skipping.`);
            await supabase.rpc('pgmq_delete', { queue_name: 'q_notifications', msg_id: msg.msg_id });
            return true;
          }

          const { title: t, body: b } = template(data);
          title = t;
          body = b;
          category = 'service';
          deepLink = undefined;

          userId = await getAffectedUserId(supabase, eventType, data);

          // Per-user fan-out for multi-user events
          if (eventType === 'event_cancelled' || eventType === 'event_updated') {
            const eventId = (data.id as string) || (data.event_id as string);
            if (eventId) {
              const { token: accessToken, projectId } = await getAccessToken(firebaseServiceAccount);
              await sendToAllParticipants(supabase, eventId, title, body, category, accessToken, projectId);
              await utils.markProcessed(traceId);
              await supabase.rpc('pgmq_delete', { queue_name: 'q_notifications', msg_id: msg.msg_id });
              return true;
            }
          }
        } else {
          // --- Schema B: legacy direct payload (backward compat) ---
          userId = payload.user_id as string;
          title = payload.title as string;
          body = payload.body as string;
          category = (payload.category as string) || 'service';
          deepLink = (payload.data as Record<string, unknown>)?.deep_link as string | undefined;
        }

        if (!userId) {
          console.warn(`[${traceId}] No userId resolved. Skipping.`);
          await supabase.rpc('pgmq_delete', { queue_name: 'q_notifications', msg_id: msg.msg_id });
          return true;
        }

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
                    title,
                    body,
                    payload.data // deep_link, category etc (Schema B compat)
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
            title: title,
            body: body,
            category: category,
            deep_link: deepLink,
            metadata: payload.data
        });

      } catch (procError) {
          const msg_ = procError instanceof Error ? procError.message : String(procError);
          console.error(`[${traceId}] Processing Failed: ${msg_}`);
          // DLQ Policy: On processing error, message is NOT deleted from queue.
          // PGMQ visibility timeout (30s) will make it available for retry.
          // After 5 retries (read_ct > 5), the DLQ check above moves it to dead_letter_queue.
          // This ensures transient failures are retried while permanent failures are captured.
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
}))
