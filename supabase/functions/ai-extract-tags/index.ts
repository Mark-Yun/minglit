import { createClient } from "@supabase/supabase-js";
import { createLLMAdapter } from "../_shared/ai/factory.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";
import { initSentry, withSentryHandler } from "../_shared/sentry_utils.ts";
import {
  buildTagExtractionPrompt,
  extractDescriptionText,
  parseTagResponse,
} from "./tag_extractor.ts";

const FN = "ai-extract-tags";
const MAX_TAGS = 5;

initSentry();

Deno.serve(withSentryHandler(async (req) => {
  console.log(`[${FN}] triggered`);
  try {
    const payload = await req.json().catch(() => ({}));
    const batchSize = (payload as { batch_size?: number }).batch_size ?? 10;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ??
      Deno.env.get("SUPABASE_REST_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl) throw new Error("Missing SUPABASE_URL");
    if (!supabaseKey) throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY");

    const supabase = createClient(supabaseUrl, supabaseKey);
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

        // 3. JSON 배열 파싱
        const tags = parseTagResponse(response);
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
              // check_tag_name_sensitivity 트리거 등에 의한 실패 — 조용히 스킵
              console.warn(
                `[${traceId}] Failed to create tag: ${tagName}`,
                insertError,
              );
              continue;
            }
            existingTag = newTag;
          }

          // party_tags에 연결 (source='ai')
          const { error: linkError } = await supabase
            .from("party_tags")
            .insert({ party_id: party.id, tag_id: existingTag.id, source: "ai" })
            .select()
            .maybeSingle();

          if (linkError) {
            // 최대 5개 제한 트리거 등에 의한 실패 — 조용히 스킵
            console.warn(
              `[${traceId}] Failed to link tag ${tagName} to party ${party.id}`,
              linkError,
            );
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
