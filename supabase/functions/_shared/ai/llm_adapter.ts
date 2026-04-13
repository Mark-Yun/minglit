export interface LLMAdapter {
  complete(
    prompt: string,
    options?: { maxTokens?: number; temperature?: number },
  ): Promise<string>;
  readonly model: string;
  readonly provider: string;
}
