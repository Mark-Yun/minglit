// Stub for @upsetjs/venn.js — published 2.0.0 ships only `src/`, no `build/`,
// so the import fails. We don't render Venn diagrams in this app, but mermaid's
// core bundle pulls the diagram chunk in for static analysis. Provide just the
// surface mermaid touches; throw if anyone actually tries to use it.
export const VennDiagram = (): never => {
  throw new Error("Venn diagrams are not supported in this build");
};
export const layout = (): never => {
  throw new Error("Venn diagrams are not supported in this build");
};
