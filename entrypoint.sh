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
# It is NOT a template variable: a `https://${{RAILWAY_PUBLIC_DOMAIN}}`
# variable value resolved to a bare `https://` in e2e (the domain did not
# exist when the variable was first evaluated), which crashed every page
# render with a Zod "Invalid URL" error. Instead, derive it at boot from
# the live RAILWAY_PUBLIC_DOMAIN injected into the running container.
# A set-but-broken value (empty, bare scheme, or an unresolved ${{...}}
# expression) is treated the same as unset; a valid user-set BASE_URL
# (e.g. a custom domain) is left alone.
case "${BASE_URL:-}" in
  ""|"http://"|"https://" | *'${{'*)
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
      export BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
      echo "[entrypoint] BASE_URL derived: ${BASE_URL}."
    else
      unset BASE_URL
      echo "[entrypoint] BASE_URL unset and no public domain; using app default."
    fi
    ;;
  *)
    echo "[entrypoint] BASE_URL kept as set."
    ;;
esac

# Chain into the upstream entrypoint: `prisma migrate deploy` (idempotent;
# also the DB readiness gate) then the standalone Next.js server, which
# listens on Railway's injected PORT (or 3000) on 0.0.0.0.
echo "[entrypoint] starting spliit (upstream entrypoint)..."
exec /bin/sh /usr/app/scripts/container-entrypoint.sh
