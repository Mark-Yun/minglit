export interface EmbeddingAdapter {
  generateEmbeddings(texts: string[]): Promise<number[][]>;
  readonly dimension: number;
  readonly model: string;
  readonly provider: string;
}
