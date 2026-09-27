# API + job workers (spec §4). Build from the repository root:
#   docker build -f apps/api/Dockerfile -t plengo-api .
FROM node:22-slim AS build
ENV PNPM_HOME=/pnpm PATH=/pnpm:$PATH
RUN corepack enable
WORKDIR /repo
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json tsconfig.base.json ./
COPY packages/contracts/package.json packages/contracts/
COPY packages/db/package.json packages/db/
COPY packages/arabic-normalizer/package.json packages/arabic-normalizer/
COPY packages/srs/package.json packages/srs/
COPY apps/api/package.json apps/api/
RUN pnpm install --frozen-lockfile --filter @plengo/api...
COPY packages/contracts packages/contracts
COPY packages/db packages/db
COPY packages/arabic-normalizer packages/arabic-normalizer
COPY packages/srs packages/srs
COPY apps/api apps/api
RUN pnpm --filter @plengo/api... run build \
 && pnpm --filter @plengo/api deploy --prod --legacy /out

FROM node:22-slim
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /out ./
USER node
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||4000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
# Run `node dist/scripts/migrate.js` as a release step before starting new containers.
CMD ["node", "dist/main.js"]
