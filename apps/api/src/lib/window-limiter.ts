/**
 * A fixed-window counter shared by several routes (in-process, like the other limits, ADR-006).
 * `@fastify/rate-limit` keeps one store per route, so a per-email limit that spans routes needs this.
 */
export class WindowLimiter {
  private readonly hits = new Map<string, { count: number; resetAt: number }>();

  constructor(
    private readonly max: number,
    private readonly windowMs: number,
    private readonly now: () => number = Date.now,
  ) {}

  /** Counts one hit; false when the key is over its limit for the current window. */
  hit(key: string): boolean {
    const at = this.now();
    const entry = this.hits.get(key);
    if (!entry || entry.resetAt <= at) {
      this.hits.set(key, { count: 1, resetAt: at + this.windowMs });
      if (this.hits.size > 10_000) this.sweep(at);
      return true;
    }
    entry.count += 1;
    return entry.count <= this.max;
  }

  private sweep(at: number) {
    for (const [key, entry] of this.hits) if (entry.resetAt <= at) this.hits.delete(key);
  }
}
