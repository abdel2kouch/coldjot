# --------------------------
# 1) Base image
# --------------------------
FROM node:22-alpine AS base

WORKDIR /app

# --------------------------
# 2) Install dependencies
# --------------------------
FROM base AS deps

RUN apk add --no-cache libc6-compat openssl

COPY package.json package-lock.json ./
COPY packages/database/package.json packages/database/
COPY apps/web/package.json apps/web/

RUN npm install

# --------------------------
# 3) Build database + app
# --------------------------
FROM deps AS builder

COPY . .

RUN npm run db:generate --workspace=packages/database
# ❌ Removed db:migrate here
RUN npm run build --workspace=apps/web

# --------------------------
# 4) Production image
# --------------------------
FROM node:22-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app/apps/web/.next ./apps/web/.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/web/package.json ./apps/web/package.json

EXPOSE 3000

CMD ["npm", "run", "start", "--workspace=apps/web"]
