export interface WorkerConfig {
  maxDurationMs: number; // e.g. 55000
  intervalMs: number;    // e.g. 5000
}

export async function runWorkerLoop(
  config: WorkerConfig,
  task: () => Promise<boolean> // returns true if messages were processed
) {
  const startTime = Date.now();
  
  while (Date.now() - startTime < config.maxDurationMs) {
    const workDone = await task();
    
    // Check time again before waiting
    if (Date.now() - startTime >= config.maxDurationMs) break;

    if (workDone) {
      // If we processed something, check again immediately (or with minimal delay) to drain queue
      // This ensures < 1s latency for bursts
      await new Promise(resolve => setTimeout(resolve, 100)); 
    } else {
      // If queue was empty, wait for the polling interval
      await new Promise(resolve => setTimeout(resolve, config.intervalMs));
    }
  }
}
