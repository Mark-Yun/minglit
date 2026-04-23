import { createServiceClient } from "../_shared/supabase_client.ts";
import { nowISO } from "../_shared/temporal_utils.ts";
import { createEmbeddingAdapter } from "../_shared/ai/factory.ts";
import { serializeParty } from "./party_serializer.ts";
import { HybridCalculator } from "./calculator.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";
import {
  captureException,
  initSentry,
  log,
  withHandler,
} from "../_shared/logger.ts";
import { requireServiceRole } from "../_shared/auth_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";

const FN = "ai-embed";

const WEIGHTS: Record<string, number> = {
  view: 0.1,
  like: 0.5,
  purchase: 1.0,
  dislike: -0.5,
};

const calculator = new HybridCalculator({ decayRate: 0.05 });

initSentry();

Deno.serve(withHandler(async (req) => {
  // Fix #1489: 시스템 전용 EF — service_role만 허용
  const auth = requireServiceRole(req);
  if (auth instanceof Response) return auth;
  log({
    function: FN,
    level: "info",
    message: "AI Embed Worker Triggered! Checking environment and auth...",
  });
  try {
    const body = await parseJsonBody(req);
    const payload = body instanceof Response ? {} : body;
    const rawBatch = Math.floor(Number(payload.batch_size));
    const batchSize = Number.isFinite(rawBatch) && rawBatch >= 1
      ? Math.min(rawBatch, 50)
      : 50;

    const supabase = createServiceClient();
    const adapter = createEmbeddingAdapter();
    const utils = new WorkerUtils(supabase, "q_vectors");

    // 1. Read Batch from PGMQ
    const { data: messages, error: readError } = await supabase.rpc(
      "pgmq_read",
      {
        queue_name: "q_vectors",
        vt: 60, // Increase VT for batch processing
        limit: batchSize,
      },
    );

    if (readError) {
      log({
        function: FN,
        level: "error",
        message: "PGMQ Read Error",
        metadata: { detail: readError },
      });
      throw readError;
    }

    if (!messages || (Array.isArray(messages) && messages.length === 0)) {
      return new Response(JSON.stringify({ processed: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const msgArray = Array.isArray(messages) ? messages : [messages];
    log({
      function: FN,
      level: "info",
      message: `Processing v2 batch of ${msgArray.length} messages`,
    });

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
        log({
          function: FN,
          level: "info",
          message: `[${traceId}] Already processed. Skipping.`,
        });
        processedMsgIds.push(msg.msg_id);
        continue;
      }

      // C. Time Tracking
      if (p.meta?.occurred_at) {
        utils.logTimeLag(p.meta.occurred_at, traceId);
      }

      // D. Queue for Processing
      if (p.type === "party_created") {
        partyTasks.push({ msgId: msg.msg_id, record: p.payload, traceId });
      } else if (p.type === "user_interaction") {
        interactionTasks.push({
          msgId: msg.msg_id,
          record: p.payload,
          traceId,
        });
      } else {
        processedMsgIds.push(msg.msg_id);
      }
    }

    // 2. Process Party Vectorization (Efficient Batching via EmbeddingAdapter)
    if (partyTasks.length > 0) {
      try {
        // Separate public and private parties
        const publicPartyTasks = partyTasks.filter((t) =>
          t.record.visibility !== "private"
        );
        const privatePartyTasks = partyTasks.filter((t) =>
          t.record.visibility === "private"
        );

        // Handle private parties - skip embedding, delete existing
        for (const t of privatePartyTasks) {
          log({
            function: FN,
            level: "info",
            message: `Skipping private party: ${t.record.id}`,
          });
          await supabase.from("party_embeddings").delete().eq(
            "party_id",
            t.record.id,
          );
          await utils.markProcessed(t.traceId);
          processedMsgIds.push(t.msgId);
        }

        // Process only public parties
        if (publicPartyTasks.length > 0) {
          const texts = publicPartyTasks.map((t) => serializeParty(t.record));
          log({
            function: FN,
            level: "info",
            message: `Requesting ${texts.length} embeddings...`,
          });
          const embeddings = await adapter.generateEmbeddings(texts);
          log({
            function: FN,
            level: "info",
            message: `Received ${embeddings.length} embeddings.`,
          });

          for (let i = 0; i < publicPartyTasks.length; i++) {
            const t = publicPartyTasks[i];
            const item = {
              party_id: t.record.id,
              embedding: embeddings[i],
              updated_at: nowISO(),
            };

            const { error: upsertError } = await supabase.from(
              "party_embeddings",
            ).upsert(item);
            if (upsertError) {
              log({
                function: FN,
                level: "error",
                message: `Upsert Error for party ${t.record.id}`,
                metadata: { detail: JSON.stringify(upsertError) },
              });
            } else {
              log({
                function: FN,
                level: "info",
                message:
                  `Successfully saved embedding for party ${t.record.id}`,
              });
              await utils.markProcessed(t.traceId);
              processedMsgIds.push(t.msgId);
            }
          }
        }
      } catch (e) {
        // Fix #1441: 에러를 삼키지 말고 throw — PGMQ retry 활용 (silent failure 방지)
        log({
          function: FN,
          level: "error",
          message: "Party Vectorization Error",
          metadata: { error: e },
        });
        throw e;
      }
    }

    // 3. Process User Interactions
    for (const task of interactionTasks) {
      try {
        const { user_id, party_id, action_type } = task.record;
        const weight = WEIGHTS[action_type] ?? 0;

        const [userRes, partyRes] = await Promise.all([
          supabase.from("user_embeddings").select("embedding").eq(
            "user_id",
            user_id,
          ).maybeSingle(),
          supabase.from("party_embeddings").select("embedding").eq(
            "party_id",
            party_id,
          ).maybeSingle(),
        ]);

        // Fix #1441: DB 쿼리 에러 미검증 — 에러 시 throw로 PGMQ retry 활용
        if (userRes.error) throw userRes.error;
        if (partyRes.error) throw partyRes.error;

        if (partyRes.data && partyRes.data.embedding) {
          const oldVector = userRes.data?.embedding ?? new Array(1536).fill(0);
          const newVector = calculator.calculate(
            oldVector,
            partyRes.data.embedding,
            weight,
          );

          const { error } = await supabase.from("user_embeddings").upsert({
            user_id,
            embedding: newVector,
            updated_at: nowISO(),
          });
          if (error) throw error;

          await utils.markProcessed(task.traceId);
          processedMsgIds.push(task.msgId);
        } else {
          log({
            function: FN,
            level: "warn",
            message:
              `Skipping interaction: Party ${party_id} embedding not found.`,
          });
          processedMsgIds.push(task.msgId);
        }
      } catch (e) {
        log({
          function: FN,
          level: "error",
          message: "Interaction Error",
          metadata: { error: e },
        });
      }
    }

    // 4. Delete processed messages from queue individually for reliability
    if (processedMsgIds.length > 0) {
      log({
        function: FN,
        level: "info",
        message: `Deleting ${processedMsgIds.length} messages from queue...`,
      });
      for (const msgId of processedMsgIds) {
        const { error: delError } = await supabase.rpc("pgmq_delete", {
          queue_name: "q_vectors",
          msg_id: msgId,
        });
        if (delError) {
          log({
            function: FN,
            level: "error",
            message: `PGMQ Delete Error for ${msgId}`,
            metadata: { detail: delError },
          });
        }
      }
    }

    return new Response(JSON.stringify({ processed: processedMsgIds.length }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    log({
      function: FN,
      level: "error",
      message: `AI Embed Worker Error: ${errorMessage}`,
    });
    // captureException: withHandler의 catch에 도달하지 않으므로 여기서 직접 Sentry에 캡처
    captureException(err);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}));
