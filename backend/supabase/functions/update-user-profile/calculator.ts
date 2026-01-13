export interface VectorCalculator {
  calculate(oldVector: number[], actionVector: number[], weight: number): number[];
}

export interface CalculatorConfig {
  decayRate: number; // 0 to 1
}

export class HybridCalculator implements VectorCalculator {
  constructor(private config: CalculatorConfig) {}

  calculate(oldVector: number[], actionVector: number[], weight: number): number[] {
    const decay = 1 - this.config.decayRate;
    
    // Combine vectors: (old * decay) + (new * weight)
    const combined = oldVector.map((val, i) => (val * decay) + (actionVector[i] * weight));

    // Normalize
    const magnitude = Math.sqrt(combined.reduce((sum, val) => sum + val * val, 0));
    
    if (magnitude === 0) return combined; // Avoid division by zero
    
    return combined.map(val => val / magnitude);
  }
}
