import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  poweredByHeader: false,
  reactStrictMode: true,
  // Demo hosting without a shared domain (docs/demo-hosting.md): the browser calls /api on the
  // admin's own origin and Next.js forwards it to the API, so the session cookie is first-party.
  // Set NEXT_PUBLIC_API_BASE_URL to the admin's own URL when API_PROXY_TARGET is used.
  async rewrites() {
    const target = process.env.API_PROXY_TARGET?.replace(/\/+$/, '');
    return target ? [{ source: '/api/:path*', destination: `${target}/api/:path*` }] : [];
  },
  // HTTPS only once deployed (spec §31); local development stays on http.
  async headers() {
    if (process.env.NODE_ENV !== 'production') return [];
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'same-origin' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(), payment=()' },
          // Next.js inlines its bootstrap scripts, so scripts keep 'unsafe-inline'; the policy still
          // forbids framing, plugins, foreign <base> and forms posting elsewhere, and limits network
          // access to the API and HTTPS (presigned uploads go straight to R2).
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-inline'",
              "style-src 'self' 'unsafe-inline'",
              "img-src 'self' data: blob: https:",
              "font-src 'self' data:",
              `connect-src 'self' ${process.env.NEXT_PUBLIC_API_BASE_URL ?? ''} https:`,
              "frame-ancestors 'none'",
              "object-src 'none'",
              "base-uri 'self'",
              "form-action 'self'",
            ].join('; '),
          },
        ],
      },
    ];
  },
};

export default nextConfig;
