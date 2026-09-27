import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';

export function hmacHex(secret: string, value: string): string {
  return createHmac('sha256', secret).update(value).digest('hex');
}

export function randomToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url');
}

export function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

/** IPs are only kept as keyed hashes (spec §31). */
export function createIpHasher(secret: string) {
  const key = hmacHex(secret, 'ip-hash-key');
  return (ip: string | undefined | null): string | null => (ip ? hmacHex(key, ip).slice(0, 32) : null);
}
