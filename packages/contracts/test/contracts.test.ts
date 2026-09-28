import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { z } from 'zod';
import {
  ERROR_CODES,
  ERROR_MESSAGES,
  bookmarkQuerySchema,
  createAdminBodySchema,
  errorEnvelopeSchema,
  mistakeQuerySchema,
  registerBodySchema,
  remoteConfigSchema,
  successEnvelope,
} from '../src/index.js';
import * as contracts from '../src/index.js';

const uuid = '0190a8e4-6a1e-7c3e-9d2f-6b1c2d3e4f50';
const arabic = /[؀-ۿ]/;

describe('error codes (§30.4)', () => {
  it('every code has an Arabic message', () => {
    expect(ERROR_CODES.length).toBe(Object.keys(ERROR_MESSAGES).length);
    for (const code of ERROR_CODES) expect(ERROR_MESSAGES[code], code).toMatch(arabic);
  });

  it('the error envelope accepts only known codes', () => {
    const envelope = (code: string) => ({
      success: false,
      data: null,
      error: { code, message: 'x' },
    });
    expect(errorEnvelopeSchema.safeParse(envelope('NOT_FOUND')).success).toBe(true);
    expect(errorEnvelopeSchema.safeParse(envelope('SOMETHING_ELSE')).success).toBe(false);
  });
});

describe('success envelope', () => {
  it('requires a registered schema and reuses one envelope per name', () => {
    expect(() => successEnvelope(z.object({ a: z.string() }))).toThrow();
    const named = z.object({ a: z.string() }).meta({ id: 'ContractsTestThing' });
    const first = successEnvelope(named);
    expect(successEnvelope(named)).toBe(first);
    expect(z.globalRegistry.get(first)?.id).toBe('ContractsTestThingEnvelope');
    expect(first.safeParse({ success: true, data: { a: 'x' }, error: null }).success).toBe(true);
  });
});

describe('request schemas', () => {
  it('registration requires an education level (§11.1)', () => {
    const base = { fullName: 'سارة', email: 'sara@example.com', password: 'Passw0rd!long' };
    expect(registerBodySchema.safeParse(base).success).toBe(false);
    expect(registerBodySchema.safeParse({ ...base, educationLevelId: uuid }).success).toBe(true);
  });

  it('new admins need a password of at least 10 characters', () => {
    const base = { email: 'a@example.com', fullName: 'المشرف' };
    expect(createAdminBodySchema.safeParse({ ...base, password: 'short' }).success).toBe(false);
    expect(createAdminBodySchema.safeParse({ ...base, password: 'long-enough-1' }).success).toBe(true);
  });

  it('list queries default and cap their page size', () => {
    expect(mistakeQuerySchema.parse({})).toMatchObject({ status: 'active', limit: 100 });
    expect(mistakeQuerySchema.safeParse({ limit: '501' }).success).toBe(false);
    expect(bookmarkQuerySchema.parse({ limit: '20' }).limit).toBe(20);
    expect(bookmarkQuerySchema.safeParse({ limit: '201' }).success).toBe(false);
  });

  it('remote config versions must be x.y.z', () => {
    const v = { android: '1.0.0', ios: '1.0.0', web: '1.0.0' };
    const config = {
      minSupportedVersion: v,
      latestVersion: v,
      features: {
        teacherFollowing: true,
        randomPractice: true,
        studentDecks: true,
        streaks: true,
        contentReports: true,
      },
      srsDefaults: { newCardsPerDay: 20, maxReviewsPerDay: 200 },
      support: { email: 'support@example.com', whatsapp: '' },
      storeUrls: { android: '', ios: '' },
      privacyPolicyUrl: '',
      termsUrl: '',
    };
    expect(remoteConfigSchema.safeParse(config).success).toBe(true);
    const bad = { ...config, latestVersion: { ...v, web: '1.0' } };
    expect(remoteConfigSchema.safeParse(bad).success).toBe(false);
  });
});

describe('partial updates', () => {
  it('never inject defaults, so omitted fields keep their stored values', () => {
    const updates = Object.entries(contracts).filter(
      ([name, schema]) => /^(update|patch)/i.test(name) && schema instanceof z.ZodObject,
    );
    expect(updates.length).toBeGreaterThan(5);
    for (const [name, schema] of updates) {
      const parsed = (schema as z.ZodObject).safeParse({});
      if (parsed.success) expect({ name, data: parsed.data }).toEqual({ name, data: {} });
    }
  });
});

describe('openapi.json', () => {
  const doc = JSON.parse(readFileSync(new URL('../openapi.json', import.meta.url), 'utf8')) as {
    paths: Record<string, Record<string, { responses: Record<string, unknown> }>>;
    components: { schemas: Record<string, unknown> };
  };

  it('has no payment wording in the public config (§0)', () => {
    const config = JSON.stringify(doc.components.schemas['RemoteConfig'] ?? {});
    expect(config).not.toMatch(/price|payment|purchase|subscription/i);
  });

  it('names every response body instead of inlining it', () => {
    for (const [path, ops] of Object.entries(doc.paths)) {
      for (const [method, op] of Object.entries(ops)) {
        for (const [status, response] of Object.entries(op.responses)) {
          const schema = (response as { content?: Record<string, { schema?: { $ref?: string } }> }).content?.[
            'application/json'
          ]?.schema;
          if (schema) expect(schema.$ref, `${method} ${path} ${status}`).toBeTruthy();
        }
      }
    }
  });

  it('names nested objects whose generated Dart class would clash with dio or Flutter types', () => {
    // swagger_parser names an unnamed nested object after its property (`options` → `Options`).
    const reserved = new Set(['options', 'headers', 'response', 'data', 'error', 'image', 'text', 'icon']);
    type Schema = { type?: string; properties?: Record<string, Schema>; items?: Schema };
    const offenders: string[] = [];
    for (const [name, schema] of Object.entries(doc.components.schemas as Record<string, Schema>)) {
      for (const [prop, value] of Object.entries(schema.properties ?? {})) {
        const inline = value.type === 'array' ? value.items : value;
        if (inline?.type === 'object' && inline.properties && reserved.has(prop))
          offenders.push(`${name}.${prop}`);
      }
    }
    expect(offenders).toEqual([]);
  });
});
