import type { FastifyReply, FastifyRequest } from 'fastify';
import { toFetchHeaders } from '../authorization/guards.js';
import type { RequestMeta } from '../services/auth-service.js';

export function requestMeta(request: FastifyRequest, hashIp: (ip: string) => string | null): RequestMeta {
  return {
    headers: toFetchHeaders(request),
    ipHash: hashIp(request.ip),
    userAgent: request.headers['user-agent']?.slice(0, 200) ?? null,
  };
}

export function forwardCookies(reply: FastifyReply, setCookies: string[]) {
  if (setCookies.length) void reply.header('set-cookie', setCookies);
}

/** Rate-limit key: client IP plus the normalized email in the body (spec §31 login limit). */
export function ipAndEmailKey(request: FastifyRequest): string {
  const email = (request.body as { email?: unknown } | undefined)?.email;
  return `${request.ip}|${typeof email === 'string' ? email.trim().toLowerCase() : ''}`;
}

export function emailKey(request: FastifyRequest): string {
  const email = (request.body as { email?: unknown } | undefined)?.email;
  return typeof email === 'string' ? `email|${email.trim().toLowerCase()}` : `ip|${request.ip}`;
}
