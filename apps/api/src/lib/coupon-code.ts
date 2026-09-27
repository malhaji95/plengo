import { createCipheriv, createDecipheriv, randomBytes, randomInt } from 'node:crypto';
import { hmacHex } from './crypto.js';

/* Coupon codes (spec §9.2, §9.3). Codes carry no subject, level or teacher information. */

export const COUPON_ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
export const COUPON_LENGTH = 10;
const VALID = new RegExp(`^[${COUPON_ALPHABET}]{${COUPON_LENGTH}}$`);

/** 10 characters from a CSPRNG (rejection-free: randomInt is uniform). */
export function generateCouponCode(): string {
  let code = '';
  for (let i = 0; i < COUPON_LENGTH; i++) code += COUPON_ALPHABET[randomInt(COUPON_ALPHABET.length)];
  return code;
}

/** `XXXX-XXXX-XX`, as printed on cards and exports. */
export const formatCouponCode = (code: string) => `${code.slice(0, 4)}-${code.slice(4, 8)}-${code.slice(8)}`;

/**
 * Trim, drop spaces and dashes, map Arabic-Indic (٠–٩) and Persian (۰–۹) digits to ASCII, uppercase.
 * Returns null when the result is not a well-formed code (callers answer COUPON_NOT_FOUND).
 */
export function normalizeCouponCode(input: string): string | null {
  const code = input
    .trim()
    .replace(/[\s\-‐-―−]/g, '')
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 0x06f0))
    .toUpperCase();
  return VALID.test(code) ? code : null;
}

export function createCouponCrypto(hmacSecret: string, encryptionKeyBase64: string) {
  const key = Buffer.from(encryptionKeyBase64, 'base64');
  if (key.length !== 32) throw new Error('COUPON_ENCRYPTION_KEY must be 32 bytes');

  return {
    hash: (normalized: string) => hmacHex(hmacSecret, normalized),

    /** AES-256-GCM; stored as base64url `iv.tag.ciphertext`. */
    encrypt(code: string): string {
      const iv = randomBytes(12);
      const cipher = createCipheriv('aes-256-gcm', key, iv);
      const ct = Buffer.concat([cipher.update(code, 'utf8'), cipher.final()]);
      return [iv, cipher.getAuthTag(), ct].map((b) => b.toString('base64url')).join('.');
    },

    decrypt(stored: string): string {
      const [iv, tag, ct] = stored.split('.').map((p) => Buffer.from(p, 'base64url')) as [
        Buffer,
        Buffer,
        Buffer,
      ];
      const decipher = createDecipheriv('aes-256-gcm', key, iv);
      decipher.setAuthTag(tag);
      return Buffer.concat([decipher.update(ct), decipher.final()]).toString('utf8');
    },
  };
}

export type CouponCrypto = ReturnType<typeof createCouponCrypto>;
