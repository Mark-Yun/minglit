export interface VectorCalculator {
  calculate(oldVector: number[], actionVector: number[], weight: number): number[];
}

export interface CalculatorConfig {
  decayRate: number; 
}

export class HybridCalculator implements VectorCalculator {
  constructor(private config: CalculatorConfig) {}

  calculate(oldVector: number[], actionVector: number[], weight: number): number[] {
    // Fix #1441: 벡터 차원 불일치 방어 — NaN 생성 방지
    if (oldVector.length !== actionVector.length) {
      throw new Error(`Vector dimension mismatch: oldVector(${oldVector.length}) !== actionVector(${actionVector.length})`);
    }
    const decay = 1 - this.config.decayRate;
    const combined = oldVector.map((val, i) => (val * decay) + (actionVector[i] * weight));
    const magnitude = Math.sqrt(combined.reduce((sum, val) => sum + val * val, 0));
    if (magnitude === 0) return combined;
    return combined.map(val => val / magnitude);
  }
}
