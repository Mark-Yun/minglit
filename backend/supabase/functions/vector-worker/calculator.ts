export interface VectorCalculator {
  calculate(oldVector: number[], actionVector: number[], weight: number): number[];
}

export interface CalculatorConfig {
  decayRate: number; 
}

export class HybridCalculator implements VectorCalculator {
  constructor(private config: CalculatorConfig) {}

  calculate(oldVector: number[], actionVector: number[], weight: number): number[] {
    const decay = 1 - this.config.decayRate;
    const combined = oldVector.map((val, i) => (val * decay) + (actionVector[i] * weight));
    const magnitude = Math.sqrt(combined.reduce((sum, val) => sum + val * val, 0));
    if (magnitude === 0) return combined;
    return combined.map(val => val / magnitude);
  }
}
