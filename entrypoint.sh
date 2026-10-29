#!/bin/sh
# Spliit entrypoint for Railway — see Dockerfile header for the why.
set -e

# Compose the two Prisma connection strings from single-ref template
# variables (SPLIIT_DB_HOST = ${{postgres.RAILWAY_PRIVATE_DOMAIN}},
# SPLIIT_DB_PASSWORD = ${{postgres.POSTGRES_PASSWORD}}) plus baked
# constants. Both point at the direct connection: Railway has no pooler
# in front of the companion, and migrate deploy needs the direct URL.
if [ -n "${SPLIIT_DB_HOST:-}" ] && [ -n "${SPLIIT_DB_PASSWORD:-}" ]; then
  export POSTGRES_PRISMA_URL="postgresql://spliit:${SPLIIT_DB_PASSWORD}@${SPLIIT_DB_HOST}:5432/spliit"
  export POSTGRES_URL_NON_POOLING="$POSTGRES_PRISMA_URL"
  echo "[entrypoint] postgres wired to ${SPLIIT_DB_HOST}:5432/spliit."
else
  echo "[entrypoint] WARNING: SPLIIT_DB_HOST/SPLIIT_DB_PASSWORD unset; database URLs left as-is."
fi

# Public base URL for metadata links (and server-action allowed origins).
# Prefer the template variable; derive from the Railway public domain as
# a fallback so a deploy without the variable still links correctly.
if [ -z "${BASE_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
  echo "[entrypoint] BASE_URL derived: ${BASE_URL}."
fi

# Chain into the upstream entrypoint: `prisma migrate deploy` (idempotent;
# also the DB readiness gate) then the standalone Next.js server, which
# listens on Railway's injected PORT (or 3000) on 0.0.0.0.
echo "[entrypoint] starting spliit (upstream entrypoint)..."
exec /bin/sh /usr/app/scripts/container-entrypoint.sh
