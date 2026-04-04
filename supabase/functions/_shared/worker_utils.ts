import { SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import { nowUnix } from './temporal_utils.ts'

export class WorkerUtils {
  constructor(private supabase: SupabaseClient, private queueName: string) {}

  /**
   * Checks if the event has already been processed.
   */
  async isProcessed(eventId: string): Promise<boolean> {
    if (!eventId) return false;
    const { data } = await this.supabase
      .from('processed_events')
      .select('id')
      .eq('id', eventId)
      .maybeSingle();
    return !!data;
  }

  /**
   * Marks the event as processed.
   */
  async markProcessed(eventId: string) {
    if (!eventId) return;
    await this.supabase.from('processed_events').insert({ id: eventId });
  }

  /**
   * Moves a failed message to the Dead Letter Queue.
   */
  // deno-lint-ignore no-explicit-any
  async moveToDLQ(msgId: number, payload: any, reason: string) {
    console.error(`[DLQ] Moving message ${msgId} to DLQ. Reason: ${reason}`);
    await this.supabase.from('dead_letter_queue').insert({
      msg_id: msgId,
      queue_name: this.queueName,
      payload: payload,
      error_reason: reason
    });
    
    // Delete from original queue to stop retries
    await this.supabase.rpc('pgmq_delete', {
      queue_name: this.queueName,
      msg_id: msgId
    });
  }

  /**
   * Logs the time lag between event occurrence and processing.
   */
  logTimeLag(occurredAtUnix: number, traceId: string) {
    // Fix #446: Date → Temporal API migration
    const now = nowUnix();
    const lag = now - occurredAtUnix;
    console.log(`[${traceId}] Processed with Lag: ${lag}s`);
    if (lag > 10) {
      console.warn(`[${traceId}] High Latency Detected: ${lag}s`);
    }
  }
}
