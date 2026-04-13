import { createServiceClient } from "../_shared/supabase_client.ts";
import { createLLMAdapter } from "../_shared/ai/factory.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";
import { requireServiceRole } from "../_shared/auth_utils.ts";
import {
  buildTagExtractionPrompt,
  extractDescriptionText,
  parseTagResponse,
} from "./tag_extractor.ts";

const FN = "ai-extract-tags";
const MAX_TAGS = 5;

// Known constraint violation codes — expected errors that should be skipped (not retried)
const EXPECTED_CONSTRAINT_CODES = new Set([
  "23514", // check_violation      — sensitivity filter, source check
  "23505", // unique_violation     — duplicate tag link
  "P0001", // raise_exception      — max-limit trigger (PL/pgSQL RAISE)
]);

initSentry();

Deno.serve(withHandler(async (req) => {
  console.log(`[${FN}] triggered`);

  // Caller verification: only cron (publishable_key) or service role may invoke this function
  const authCheck = requireServiceRole(req);
  if (authCheck instanceof Response) return authCheck;

  try {
    const payload = await req.json().catch(() => ({}));
    const batchSize = (payload as { batch_size?: number }).batch_size ?? 10;

    const supabase = createServiceClient();
    // createLLMAdapter() throws if OPENAI_API_KEY is missing
    const llm = createLLMAdapter();
    const utils = new WorkerUtils(supabase, "q_tags");

    // 1. PGMQ 배치 읽기
    const { data: messages, error: readError } = await supabase.rpc(
      "pgmq_read",
      {
        queue_name: "q_tags",
        vt: 120,
        limit: batchSize,
      },
    );

    if (readError) {
      console.error(`[${FN}] PGMQ Read Error:`, readError);
      throw readError;
    }

    if (!messages || (Array.isArray(messages) && messages.length === 0)) {
      return new Response(JSON.stringify({ processed: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const msgArray = Array.isArray(messages) ? messages : [messages];
    console.log(`[${FN}] Processing ${msgArray.length} messages`);

    const processedMsgIds: number[] = [];

    for (const msg of msgArray) {
      const p = msg.message as {
        id: string;
        type: string;
        payload: {
          id: string;
          title?: string;
          description?: unknown;
        };
        meta?: { occurred_at?: number };
      };
      const traceId = p.id;

      // A. DLQ check
      if (msg.read_ct > 5) {
        await utils.moveToDLQ(msg.msg_id, p, "Max retries exceeded");
        continue;
      }

      // B. Idempotency check
      if (await utils.isProcessed(traceId)) {
        console.log(`[${traceId}] Already processed. Skipping.`);
        processedMsgIds.push(msg.msg_id);
        continue;
      }

      // C. Time tracking
      if (p.meta?.occurred_at) {
        utils.logTimeLag(p.meta.occurred_at, traceId);
      }

      // D. party_created 이벤트만 처리
      if (p.type !== "party_created") {
        processedMsgIds.push(msg.msg_id);
        continue;
      }

      const party = p.payload;

      try {
        // 1. Description 텍스트 추출
        const descText = extractDescriptionText(party.description);

        // 2. LLM에 태그 추출 요청
        const prompt = buildTagExtractionPrompt(party.title ?? "", descText);
        const response = await llm.complete(prompt, {
          maxTokens: 100,
          temperature: 0.3,
        });

        // 3. JSON 배열 파싱 — null이면 LLM이 유효한 응답을 반환하지 않은 것
        const tags = parseTagResponse(response);
        if (tags === null) {
          console.warn(
            `[${traceId}] LLM returned unparseable response — skipping tag extraction`,
          );
          processedMsgIds.push(msg.msg_id);
          continue;
        }
        console.log(
          `[${traceId}] Extracted tags: ${JSON.stringify(tags)}`,
        );

        // 4. 태그 조회/생성 + party_tags 연결
        for (const tagName of tags.slice(0, MAX_TAGS)) {
          let { data: existingTag } = await supabase
            .from("tags")
            .select("id")
            .eq("name", tagName)
            .maybeSingle();

          if (!existingTag) {
            const { data: newTag, error: insertError } = await supabase
              .from("tags")
              .insert({ name: tagName })
              .select("id")
              .single();

            if (insertError) {
              if (EXPECTED_CONSTRAINT_CODES.has(insertError.code)) {
                // check_tag_name_sensitivity 트리거 등 예상된 제약 위반 — 조용히 스킵
                console.warn(
                  `[${traceId}] Tag "${tagName}" rejected by constraint (${insertError.code}) — skipping`,
                );
                continue;
              }
              // 예상치 못한 DB 에러 — 메시지를 큐에 남기기 위해 throw
              throw insertError;
            }
            existingTag = newTag;
          }

          // party_tags에 연결 (source='ai')
          const { error: linkError } = await supabase
            .from("party_tags")
            .insert({ party_id: party.id, tag_id: existingTag.id, source: "ai" });

          if (linkError) {
            if (EXPECTED_CONSTRAINT_CODES.has(linkError.code)) {
              // unique_violation(중복) 또는 max-limit 트리거 — 조용히 스킵
              console.warn(
                `[${traceId}] Tag link "${tagName}" → party "${party.id}" rejected (${linkError.code}) — skipping`,
              );
              continue;
            }
            // 예상치 못한 DB 에러 — 메시지를 큐에 남기기 위해 throw
            throw linkError;
          }
        }

        await utils.markProcessed(traceId);
        processedMsgIds.push(msg.msg_id);
      } catch (e) {
        console.error(`[${traceId}] Tag extraction error:`, e);
        // 이 메시지는 processedMsgIds에 추가하지 않아 큐에 남김
      }
    }

    // 5. 처리된 메시지 큐에서 삭제
    for (const msgId of processedMsgIds) {
      const { error: delError } = await supabase.rpc("pgmq_delete", {
        queue_name: "q_tags",
        msg_id: msgId,
      });
      if (delError) {
        console.error(`[${FN}] PGMQ Delete Error for ${msgId}:`, delError);
      }
    }

    return new Response(
      JSON.stringify({ processed: processedMsgIds.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    console.error(`[${FN}] Error: ${errorMessage}`);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}));
