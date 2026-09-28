import { createSign } from 'node:crypto';
import type { FastifyBaseLogger } from 'fastify';

export type PushMessage = { title: string; body: string; data?: Record<string, string> };
export type PushResult = { sent: number; failed: number; invalidTokens: string[] };

/** Sends push notifications (spec §20.3). Failures are counted and logged, never retried forever. */
export interface PushSender {
  send(tokens: string[], message: PushMessage): Promise<PushResult>;
}

/** Development and tests: records what would be sent. */
export class RecordingPushSender implements PushSender {
  readonly sent: { tokens: string[]; message: PushMessage }[] = [];
  /** Tokens to report as no longer registered. */
  invalid = new Set<string>();

  constructor(private readonly log?: FastifyBaseLogger) {}

  async send(tokens: string[], message: PushMessage): Promise<PushResult> {
    this.sent.push({ tokens, message });
    this.log?.info({ tokens: tokens.length, title: message.title }, 'push (not sent: no FCM credentials)');
    const invalidTokens = tokens.filter((t) => this.invalid.has(t));
    return { sent: tokens.length - invalidTokens.length, failed: invalidTokens.length, invalidTokens };
  }
}

type Fetch = typeof fetch;

/**
 * Firebase Cloud Messaging, HTTP v1 API, with a service account (no SDK): an RS256-signed JWT is
 * exchanged for a one-hour access token, then one request per device token. Tokens FCM reports as
 * unregistered are returned so they can be revoked.
 */
export class FcmPushSender implements PushSender {
  private accessToken: { value: string; expiresAt: number } | null = null;

  constructor(
    private readonly config: { projectId: string; clientEmail: string; privateKey: string },
    private readonly log: FastifyBaseLogger,
    private readonly http: Fetch = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  private jwt() {
    const b64 = (v: object) => Buffer.from(JSON.stringify(v)).toString('base64url');
    const iat = Math.floor(this.now() / 1000);
    const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64({
      iss: this.config.clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat,
      exp: iat + 3600,
    })}`;
    const signature = createSign('RSA-SHA256')
      .update(unsigned)
      .sign(this.config.privateKey)
      .toString('base64url');
    return `${unsigned}.${signature}`;
  }

  private async token() {
    if (this.accessToken && this.accessToken.expiresAt > this.now() + 60_000) return this.accessToken.value;
    const res = await this.http('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: this.jwt(),
      }).toString(),
    });
    if (!res.ok) throw new Error(`FCM auth failed: ${res.status}`);
    const body = (await res.json()) as { access_token: string; expires_in: number };
    this.accessToken = { value: body.access_token, expiresAt: this.now() + body.expires_in * 1000 };
    return body.access_token;
  }

  async send(tokens: string[], message: PushMessage): Promise<PushResult> {
    const result: PushResult = { sent: 0, failed: 0, invalidTokens: [] };
    if (!tokens.length) return result;
    let access: string;
    try {
      access = await this.token();
    } catch (err) {
      this.log.error({ err }, 'push: FCM authentication failed');
      return { ...result, failed: tokens.length };
    }
    const url = `https://fcm.googleapis.com/v1/projects/${this.config.projectId}/messages:send`;
    for (const token of tokens) {
      try {
        const res = await this.http(url, {
          method: 'POST',
          headers: { authorization: `Bearer ${access}`, 'content-type': 'application/json' },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: message.title, body: message.body },
              data: message.data ?? {},
              android: { priority: 'HIGH' },
            },
          }),
        });
        if (res.ok) {
          result.sent++;
          continue;
        }
        result.failed++;
        const error = ((await res.json().catch(() => ({}))) as { error?: { status?: string } }).error;
        if (res.status === 404 || error?.status === 'NOT_FOUND' || error?.status === 'UNREGISTERED') {
          result.invalidTokens.push(token);
        } else {
          this.log.warn({ status: res.status, fcm: error?.status }, 'push: send failed');
        }
      } catch (err) {
        result.failed++;
        this.log.warn({ err }, 'push: request failed');
      }
    }
    return result;
  }
}
